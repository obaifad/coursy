import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/register_payload.dart';
import 'package:my_app/core/models/student_profile_payload.dart';
import 'package:my_app/core/utils/app_toast.dart';
import 'package:my_app/modules/auth/widgets/register_form_widgets.dart';
import 'package:my_app/modules/profile/controllers/profile_controller.dart';
import 'package:my_app/modules/profile/views/profile_views.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// الخادم صار يرسل إشعار «دورة جديدة» لمن اختار تصنيف الدورة في اهتماماته فقط (لا لأهل مدينة المعهد).
/// التطبيق يقول ذلك تحت حقل الاهتمامات (إنشاء الحساب وتعديل الملف)، ولم يعد يعرف «نطاق الإشعارات» بالكيلومتر
/// الذي لم يستخدمه الخادم قط.
void main() {
  setUpAll(loadAuditFonts);
  setUp(() => AppToast.onShow = (_, __, ___) {});
  tearDown(() {
    AppToast.onShow = null;
    Get.reset();
  });

  group('translations', () {
    final keys = AppTranslations().keys;

    test('the interests hint exists in both languages', () {
      expect(keys['ar_SY']?['interests_notify_hint'] ?? keys['ar']?['interests_notify_hint'], contains('اهتماماتك'));
      expect(keys['en_US']?['interests_notify_hint'] ?? keys['en']?['interests_notify_hint'], contains('interests'));
    });

    test('the notification radius text is gone', () {
      for (final map in keys.values) {
        expect(map.containsKey('notification_radius'), isFalse);
      }
    });

    test('the empty notifications hint says new courses follow your interests', () {
      final ar = keys['ar_SY']?['notifications_empty_hint'] ?? keys['ar']?['notifications_empty_hint'];
      expect(ar, contains('اهتماماتك'));
    });
  });

  group('payloads', () {
    test('sign-up never sends notification_radius_km', () {
      final json = RegisterPayload(
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.c',
        password: 'secret12',
        passwordConfirmation: 'secret12',
        preferredCategories: const [3],
      ).toJson();
      expect(json.toString(), isNot(contains('notification_radius_km')));
      expect((json['student_profile'] as Map)['preferred_categories'], [3]);
    });

    test('profile save never sends notification_radius_km', () {
      final json = StudentProfilePayload(preferredCategories: const [3]).toJson();
      expect(json.toString(), isNot(contains('notification_radius_km')));
      expect((json['student_profile'] as Map)['preferred_categories'], [3]);
    });
  });

  group('hint under the interests field', () {
    testWidgets('sign-up: shown with the interests picker', (tester) async {
      await registerFakes(loggedIn: false, locale: 'ar');
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('ar'),
          home: Scaffold(
            body: RegisterInterestPicker(
              categories: [CategoryModel(id: 3, nameAr: 'برمجة', nameEn: 'Programming')],
              selectedIds: const [],
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('interests_notify_hint'.tr), findsOneWidget);
    });

    testWidgets('sign-up: not shown when the server has no categories (the field is hidden)', (tester) async {
      await registerFakes(loggedIn: false, locale: 'ar');
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: RegisterInterestPicker(categories: const [], selectedIds: const [], onApply: (_) {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('interests_notify_hint'.tr), findsNothing);
    });

    testWidgets('edit profile: shown in the interests section', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await registerFakes(loggedIn: true, locale: 'ar');
      final c = Get.put(ProfileController());
      await tester.pumpWidget(
        GetMaterialApp(translations: AppTranslations(), locale: const Locale('ar'), home: const EditProfileView()),
      );
      await tester.pumpAndSettle();
      c.categories.assignAll([CategoryModel(id: 3, nameAr: 'برمجة', nameEn: 'Programming')]);
      c.listsLoading.value = false;
      await tester.pump();
      expect(find.text('interests_notify_hint'.tr, skipOffstage: false), findsOneWidget);
    });
  });
}
