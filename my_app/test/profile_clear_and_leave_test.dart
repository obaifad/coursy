import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/profile_repository.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/models/student_profile_payload.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/core/utils/app_toast.dart';
import 'package:my_app/modules/profile/controllers/profile_controller.dart';
import 'package:my_app/modules/profile/views/profile_views.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// خادم وهمي يطبّق PATCH كما يُنتظر منه: `null`/`[]` يمسح الحقل، والمحذوف يبقى كما هو.
class _Server implements HttpClientAdapter {
  final Map<String, dynamic> profile = {
    'education_level': 'Bachelor',
    'university_id': 1,
    'specialization_id': 1,
    'preferred_categories': [3, 5],
  };
  final patches = <Map<String, dynamic>>[];

  Map<String, dynamic> get _user => {
    'id': 1,
    'first_name': 'عبد الرحمن',
    'last_name': 'الخطيب',
    'phone': '0999123456',
    'gender': 'male',
    'student_profile': Map<String, dynamic>.from(profile),
  };

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    if (o.method == 'PATCH' && o.path == '/student/profile') {
      final body = Map<String, dynamic>.from(o.data as Map);
      patches.add(body);
      final nested = (body['student_profile'] as Map?) ?? const {};
      for (final key in ['education_level', 'university_id', 'specialization_id', 'preferred_categories']) {
        if (nested.containsKey(key)) profile[key] = nested[key];
      }
      profile.removeWhere((_, v) => v == null || (v is List && v.isEmpty));
    }
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode({'data': _user})),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(loadAuditFonts);
  setUp(() => AppToast.onShow = (_, __, ___) {});
  tearDown(() {
    AppToast.onShow = null;
    Get.reset();
  });

  group('payload', () {
    test('cleared fields are sent explicitly, empty ones are still left out', () {
      final json = StudentProfilePayload(
        firstName: 'عمر',
        clearFields: {'university_id', 'specialization_id', 'preferred_categories'},
      ).toJson();
      expect(json.containsKey('university_id'), isTrue);
      expect(json['university_id'], isNull);
      expect(json['preferred_categories'], <int>[]);
      final nested = json['student_profile'] as Map;
      expect(nested.containsKey('university_id'), isTrue);
      expect(nested['university_id'], isNull);
      expect(nested['preferred_categories'], <int>[]);
      expect(json.containsKey('education_level'), isFalse, reason: 'not cleared and empty -> omitted as before');
    });

    test('without clearFields nothing changes', () {
      final json = StudentProfilePayload(firstName: 'عمر').toJson();
      expect(json, {'first_name': 'عمر'});
    });

    test('unknown names are ignored', () {
      expect(StudentProfilePayload(clearFields: {'password'}).toJson(), isEmpty);
    });
  });

  group('saving', () {
    late _Server server;
    late TokenStorage tokens;
    late ProfileController c;

    /// الحفظ يعرض تنبيه نجاح (Get.snackbar) فيحتاج Overlay: تطبيق GetX حقيقي، والعمل الفعلي داخل runAsync.
    Future<void> open(WidgetTester tester) async {
      // registerFakes يعيد ضبط Get (ومعه مفتاح التنقل)، فيُنشأ التطبيق بعده كي يجد التنبيه Overlay.
      await tester.runAsync(() async {
        tokens = await registerFakes(loggedIn: true, locale: 'ar');
      });
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      await tester.runAsync(() async {
        server = _Server();
        final client = Get.find<ApiClient>();
        client.dio.httpClientAdapter = server;
        replaceFake<ProfileRepository>(ProfileRepository(client, tokens));
        c = Get.put(ProfileController());
        await c.refreshForEdit();
      });
      expect(c.selectedCategoryIds, [3, 5]);
    }

    Future<void> run(WidgetTester tester, Future<void> Function() body) async {
      await tester.runAsync(body);
      await tester.pump(const Duration(seconds: 5)); // يُنهي مؤقّت التنبيه
    }

    testWidgets('clearing every interest reaches the server and stays cleared after a reload', (tester) async {
      await open(tester);
      c.setCategoryIds([]);
      await run(tester, c.saveProfile);
      expect(server.patches.single['preferred_categories'], <int>[]);
      expect(server.profile.containsKey('preferred_categories'), isFalse);
      expect(c.selectedCategoryIds, isEmpty);
      final cache = await tester.runAsync(tokens.loadAcademicCache);
      expect(cache == null || cache.preferredCategoryIds.isEmpty, isTrue, reason: 'local copy mirrors the save');

      await run(tester, c.loadProfile);
      expect(c.selectedCategoryIds, isEmpty, reason: 'the old local copy must not refill it');
    });

    testWidgets('a reload after clearing does not bring the old interests back', (tester) async {
      await open(tester);
      c.setCategoryIds([]);
      await run(tester, c.saveProfile);
      await run(tester, c.refreshForEdit);
      expect(c.selectedCategoryIds, isEmpty);
    });

    testWidgets('switching to a level without university fields clears university and specialization', (tester) async {
      await open(tester);
      c.setEducationLevel('High School');
      await run(tester, c.saveProfile);
      final body = server.patches.single;
      expect(body.containsKey('university_id'), isTrue);
      expect(body['university_id'], isNull);
      expect(body['specialization_id'], isNull);
      expect(server.profile.containsKey('university_id'), isFalse);
      expect(c.selectedUniversityId.value, isNull);
      await run(tester, c.loadProfile);
      expect(c.selectedUniversityId.value, isNull);
    });

    testWidgets('untouched academic fields are not cleared and keep their values', (tester) async {
      await open(tester);
      c.firstNameController.text = 'عمر';
      await run(tester, c.saveProfile);
      final nested = (server.patches.single['student_profile'] as Map);
      expect(nested['university_id'], 1);
      expect(server.profile['preferred_categories'], [3, 5]);
    });

    testWidgets('after saving there is nothing pending and the page is not closed by the controller', (tester) async {
      await open(tester);
      c.firstNameController.text = 'عمر';
      expect(c.hasChanges.value, isTrue);
      await run(tester, c.saveProfile);
      expect(c.hasChanges.value, isFalse);
      expect(c.saveSucceeded.value, isTrue);
    });

    testWidgets('discardChanges restores the last loaded values', (tester) async {
      await open(tester);
      c.firstNameController.text = 'غير محفوظ';
      c.setCategoryIds([9]);
      await run(tester, c.discardChanges);
      expect(c.firstNameController.text, 'عبد الرحمن');
      expect(c.selectedCategoryIds, [3, 5]);
      expect(c.hasChanges.value, isFalse);
    });
  });

  group('leaving the page', () {
    Future<ProfileController> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await registerFakes(loggedIn: true, locale: 'ar');
      final c = Get.put(ProfileController());
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditProfileView())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('no changes: back leaves at once', (tester) async {
      await pump(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileView), findsNothing);
      expect(find.text('unsaved_leave_title'.tr), findsNothing);
    });

    testWidgets('unsaved changes: back asks first, "keep editing" stays', (tester) async {
      final c = await pump(tester);
      c.firstNameController.text = 'غير محفوظ';
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('unsaved_leave_title'.tr), findsOneWidget);

      await tester.tap(find.text('keep_editing'.tr));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileView), findsOneWidget);
      expect(c.firstNameController.text, 'غير محفوظ');
    });

    testWidgets('unsaved changes: "discard" leaves and drops the edits', (tester) async {
      final c = await pump(tester);
      final before = c.firstNameController.text;
      c.firstNameController.text = 'غير محفوظ';
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('discard_changes'.tr));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileView), findsNothing);
      expect(c.firstNameController.text, before);
      expect(c.hasChanges.value, isFalse);
    });
  });
}
