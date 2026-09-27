import 'dart:ui';

import 'package:flutter/material.dart' show FontWeight, ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:my_app/core/data/repositories/enrollment_repository.dart';
import 'package:my_app/core/data/repositories/profile_repository.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/locale/locale_request_guard.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/network/json_parser.dart';
import 'package:my_app/core/services/student_id_resolver.dart';
import 'package:my_app/core/storage/enrollment_status_store.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/core/utils/education_level_utils.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/theme/app_fonts.dart';

class _GuardProbe extends GetxController with LatestLoadGuard {}

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    Get.addTranslations(AppTranslations().keys);
  });

  setUp(() {
    Get.reset();
    Get.locale = const Locale('ar');
    Get.put(LocaleRequestGuard());
  });

  group('EnrollmentStatusStore (shared with the background isolate)', () {
    const studentId = 7;

    setUp(() => EnrollmentStatusStore.clear(studentId));

    test('statuses round-trip through storage', () async {
      await EnrollmentStatusStore.persistStatuses({1: 'pending', 2: 'approved'}, studentId);
      expect(await EnrollmentStatusStore.loadStatuses(studentId), {1: 'pending', 2: 'approved'});
    });

    test('delivered keys are merged with what the other isolate already saved', () async {
      // الفحص الخلفي حفظ مفتاحاً…
      await EnrollmentStatusStore.persistDelivered({'approved:1'}, studentId);
      // …ثم التطبيق يحفظ نسخته القديمة التي لا تعرفه — يجب ألا يضيع.
      final merged = await EnrollmentStatusStore.persistDelivered({'rejected:2'}, studentId);

      expect(merged, {'approved:1', 'rejected:2'});
      expect(await EnrollmentStatusStore.loadDelivered(studentId), {'approved:1', 'rejected:2'});
    });

    test('delivered keys are capped, keeping the newest', () async {
      final many = {for (var i = 0; i < EnrollmentStatusStore.maxDeliveredKeys + 50; i++) 'approved:$i'};
      final saved = await EnrollmentStatusStore.persistDelivered(many, studentId);

      expect(saved, hasLength(EnrollmentStatusStore.maxDeliveredKeys));
      expect(saved, contains('approved:${EnrollmentStatusStore.maxDeliveredKeys + 49}'));
      expect(saved, isNot(contains('approved:0')));
    });
  });

  group('LatestLoadGuard', () {
    test('loads of different kinds do not cancel each other', () {
      final probe = _GuardProbe();
      final filters = probe.beginLoad('filters');
      final list = probe.beginLoad();

      expect(probe.shouldApply(filters), isTrue);
      expect(probe.shouldApply(list), isTrue);

      final newerFilters = probe.beginLoad('filters');
      expect(probe.shouldApply(filters), isFalse);
      expect(probe.shouldApply(newerFilters), isTrue);
      expect(probe.shouldApply(list), isTrue);
    });

    test('a language change invalidates in-flight loads', () {
      final probe = _GuardProbe();
      final session = probe.beginLoad();
      Get.find<LocaleRequestGuard>().bump();
      expect(probe.shouldApply(session), isFalse);
    });

    test('currentLoad (load more) is dropped when a full reload starts', () {
      final probe = _GuardProbe();
      probe.beginLoad();
      final loadMore = probe.currentLoad();
      expect(probe.shouldApply(loadMore), isTrue);

      probe.beginLoad();
      expect(probe.shouldApply(loadMore), isFalse);
    });
  });

  test('periodic check merges into My Courses without dropping enrollments', () {
    final tokenStorage = TokenStorage();
    final client = ApiClient(tokenStorage);
    Get.put(tokenStorage);
    Get.put(EnrollmentRepository(client, StudentIdResolver(tokenStorage, ProfileRepository(client, tokenStorage))));
    final controller = MyCoursesController();
    controller.enrollments.assignAll([
      EnrollmentModel(id: 1, status: 'pending', paymentStatus: 'unpaid'),
      EnrollmentModel(id: 2, status: 'approved', paymentStatus: 'paid'),
    ]);

    // الفحص الدوري قد يُرجع الصفحة الأولى فقط من الخادم.
    controller.mergeEnrollments([
      EnrollmentModel(id: 1, status: 'approved', paymentStatus: 'unpaid'),
      EnrollmentModel(id: 3, status: 'pending', paymentStatus: 'unpaid'),
    ]);

    expect(controller.enrollments.map((e) => e.id), [3, 1, 2]);
    expect(controller.enrollments.firstWhere((e) => e.id == 1).status, 'approved');
  });

  test('phone verification status is unknown when the server omits the field', () {
    expect(phoneVerificationStatus(null), isNull);
    expect(phoneVerificationStatus({'phone': '0999999999'}), isNull);
    expect(phoneVerificationStatus({'phone_verified_at': null}), isFalse);
    expect(phoneVerificationStatus({'phone_verified_at': '2026-01-01T10:00:00Z'}), isTrue);
  });

  test('user-facing error text never shows technical exceptions', () {
    expect(userErrorMessage(ApiException('رسالة الخادم')), 'رسالة الخادم');
    expect(userErrorMessage(TypeError()), 'error_unexpected'.tr);
    expect(userErrorMessage(TypeError()), isNot(contains('TypeError')));
  });

  test('education helpers', () {
    expect(EducationLevelUtils.formatApiDate(DateTime(2000, 3, 5)), '2000-03-05');
    expect(EducationLevelUtils.label('Master'), 'edu_master'.tr);
    expect(EducationLevelUtils.label('Other'), 'Other');
  });

  test('bundled Tajawal font is applied without google_fonts', () {
    expect(AppFonts.tajawal(fontWeight: FontWeight.w700).fontFamily, 'Tajawal');
    final theme = AppFonts.tajawalTextTheme(ThemeData.light().textTheme);
    expect(theme.bodyMedium?.fontFamily, 'Tajawal');
    expect(theme.titleLarge?.fontFamily, 'Tajawal');
  });
}
