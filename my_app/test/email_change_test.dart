import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/profile_repository.dart';
import 'package:my_app/core/models/student_profile_payload.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/auth/widgets/change_email_sheet.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/profile/views/profile_views.dart';

import 'layout/fakes.dart';

class _EmailProfile extends ProfileRepository {
  _EmailProfile(super.client, super.tokens);

  Map<String, dynamic> response = {
    'user': {'email': 'new@example.com', 'email_verified_at': null},
  };
  ApiException? error;
  final payloads = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> updateProfile(StudentProfilePayload payload) async {
    payloads.add(payload.toJson());
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  tearDown(Get.reset);

  group('ProfileRepository.changeEmail', () {
    test('sends the current password and keeps the status the server returns', () async {
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      await tokens.saveEmailVerified(true);
      final repo = _EmailProfile(ApiClient(tokens), tokens);

      expect(await repo.changeEmail(' new@example.com ', 'secret'), isNull);
      expect(repo.payloads.single['email'], 'new@example.com');
      expect(repo.payloads.single['current_password'], 'secret');
      // عنوان جديد: يبدأ غير مؤكد.
      expect(tokens.emailVerified.value, isFalse);

      // العنوان نفسه: الخادم لا يغيّر شيئاً فيبقى مؤكداً.
      repo.response = {
        'user': {'email': 'new@example.com', 'email_verified_at': '2026-10-12T10:00:00Z'},
      };
      expect(await repo.changeEmail('new@example.com', 'secret'), isNull);
      expect(tokens.emailVerified.value, isTrue);
    });

    test('field errors: invalid email, missing or wrong password', () async {
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      final repo = _EmailProfile(ApiClient(tokens), tokens);

      expect(await repo.changeEmail('not-an-email', 'secret'), {'email': 'enter_valid_email'});
      expect(await repo.changeEmail('new@example.com', ''), {'current_password': 'current_password_required'});
      expect(repo.payloads, isEmpty);

      repo.error = ApiException(
        'The given data was invalid.',
        statusCode: 422,
        fieldErrors: {'current_password': 'The password is incorrect.'},
      );
      expect(await repo.changeEmail('new@example.com', 'wrong'), {'current_password': 'The password is incorrect.'});

      repo.error = ApiException('taken', statusCode: 422, fieldErrors: {'email': 'The email has already been taken.'});
      expect(await repo.changeEmail('taken@example.com', 'secret'), {'email': 'The email has already been taken.'});
    });
  });

  group('ChangeEmailSheet', () {
    Future<Future<bool>> openSheet(WidgetTester tester, ChangeEmailSubmit onSubmit) async {
      late Future<bool> result;
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => result = showChangeEmailSheet(context, initialEmail: 'old@example.com', onSubmit: onSubmit),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('submits once while saving, then closes without using disposed fields', (tester) async {
      final pending = Completer<Map<String, String>?>();
      var calls = 0;
      final result = await openSheet(tester, (email, password) {
        calls++;
        expect(email, 'new@example.com');
        expect(password, 'secret');
        return pending.future;
      });

      await tester.enterText(find.byType(TextField).first, 'new@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.tap(find.text('save_and_send_code'));
      await tester.pump();
      // الزر في حالة التحميل: ضغطة ثانية لا ترسل طلباً آخر.
      await tester.tap(find.byType(InkWell).last, warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);

      pending.complete(null);
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(find.byType(ChangeEmailSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the field errors and stays open', (tester) async {
      final result = await openSheet(tester, (_, _) async => {'current_password': 'كلمة المرور غير صحيحة'});

      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.tap(find.text('save_and_send_code'));
      await tester.pumpAndSettle();

      expect(find.text('كلمة المرور غير صحيحة'), findsOneWidget);
      expect(find.byType(ChangeEmailSheet), findsOneWidget);

      Navigator.of(tester.element(find.byType(ChangeEmailSheet))).pop();
      await tester.pumpAndSettle();
      expect(await result, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('Profile email rows', () {
    Future<TokenStorage> pumpProfile(WidgetTester tester, {required bool? verified}) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      if (verified != null) await tokens.saveEmailVerified(verified);
      Get.put(MyCoursesController());
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: ProfileView())));
      await tester.pump(const Duration(milliseconds: 100));
      return tokens;
    }

    testWidgets('unverified: "Verify email"; verified: "Change email"; unknown: neither', (tester) async {
      final tokens = await pumpProfile(tester, verified: false);
      expect(find.text('verify_email_title'), findsOneWidget);
      expect(find.text('change_email'), findsNothing);

      await tokens.saveEmailVerified(true);
      await tester.pump();
      expect(find.text('verify_email_title'), findsNothing);
      expect(find.text('change_email'), findsOneWidget);
    });

    testWidgets('status not sent by the server shows neither row', (tester) async {
      await pumpProfile(tester, verified: null);
      expect(find.text('verify_email_title'), findsNothing);
      expect(find.text('change_email'), findsNothing);
    });
  });
}
