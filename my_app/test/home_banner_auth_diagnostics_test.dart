import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/core/session/session_diagnostics.dart';
import 'package:my_app/core/storage/secure_session_store.dart';
import 'package:my_app/core/storage/session_keys.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/home/views/home_view.dart';
import 'package:my_app/modules/home/widgets/featured_course_carousel.dart';
import 'package:my_app/modules/home/widgets/home_status_banner.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// (ب) تشخيص الجلسة عند الإقلاع: مسجّل / ضيف / ضاعت من التخزين الآمن / فشلت القراءة — والحالتان الشاذتان
/// فقط تُبلَّغان. (ج) أعلى الرئيسية للمسجّل: لا بطاقة «لا دورات» الافتراضية قبل أن يؤكّد الخادم الدورات
/// (فشل الشبكة أو نسخة محفوظة كانا يُظهرانها ثم تُستبدل بالشرائح).
class _ThrowingStore extends SecureSessionStore {
  @override
  Future<Map<String, String>> readAll() async => throw PlatformException(code: 'decrypt', message: 'decryption failed');
}

class _ClosedCourses extends CourseRepository {
  _ClosedCourses(ApiClient client) : super(client, Get.find<CourseRatingService>());

  @override
  Future<List<CourseModel>> fetchCourses({Map<String, dynamic>? query}) async => [
    sampleCourses().firstWhere((c) => c.isRegistrationClosed),
  ];
  @override
  Future<List<CourseModel>> fetchSuggestedCourses({int limit = 10}) async => const [];
}

void main() {
  group('session boot diagnostics', () {
    late Directory dir;
    final reports = <SessionBootOutcome>[];

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('session_boot_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      );
      await GetStorage.init();
    });

    setUp(() async {
      await GetStorage().erase();
      FlutterSecureStorage.setMockInitialValues({});
      reports.clear();
      SessionDiagnostics.lastBoot = null;
      SessionDiagnostics.reporter = (outcome, _, _) => reports.add(outcome);
    });
    tearDown(() => SessionDiagnostics.reporter = null);

    Future<TokenStorage> bootAndWait() async {
      final storage = TokenStorage();
      await storage.init();
      return storage;
    }

    test('first launch: guest, nothing reported', () async {
      final s = await bootAndWait();
      expect(s.isLoggedIn, isFalse);
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.guest);
      expect(reports, isEmpty);
    });

    test('after signing in: signed in on the next launch, nothing reported', () async {
      await (await bootAndWait()).saveSession(token: 't-1');
      final s = await bootAndWait();
      expect(s.isLoggedIn, isTrue);
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.signedIn);
      expect(reports, isEmpty);
    });

    test('signed in, then the secure storage loses the session: reported once as lost', () async {
      await (await bootAndWait()).saveSession(token: 't-1');
      FlutterSecureStorage.setMockInitialValues({}); // ما يفعله resetOnError بعد خطأ فك تشفير
      final s = await bootAndWait();
      expect(s.isLoggedIn, isFalse);
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.lost);
      expect(reports, [SessionBootOutcome.lost]);

      await bootAndWait();
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.guest, reason: 'reported once, then a plain guest');
      expect(reports, [SessionBootOutcome.lost]);
    });

    test('signing out is not a lost session', () async {
      final s = await bootAndWait();
      await s.saveSession(token: 't-1');
      await s.clearSession();
      await bootAndWait();
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.guest);
      expect(reports, isEmpty);
    });

    test('a user from an older version (no marker) is tracked from now on', () async {
      FlutterSecureStorage.setMockInitialValues({
        SessionKeys.accessToken: 't-old',
        SessionKeys.storageVersion: SessionKeys.currentStorageVersion,
      });
      await bootAndWait();
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.signedIn);
      FlutterSecureStorage.setMockInitialValues({});
      await bootAndWait();
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.lost);
    });

    test('the secure read throws: reported as read failed, the app starts as a guest', () async {
      final s = TokenStorage(secureStore: _ThrowingStore());
      await expectLater(s.init(), throwsA(isA<PlatformException>()));
      expect(s.isLoggedIn, isFalse);
      expect(SessionDiagnostics.lastBoot, SessionBootOutcome.readFailed);
      expect(reports, [SessionBootOutcome.readFailed]);
    });
  });

  group('home banner for a signed-in user', () {
    setUpAll(loadAuditFonts);
    tearDown(() {
      FakeApi.reset();
      Get.reset();
    });

    Future<void> openHome(WidgetTester tester, {void Function()? arrange}) async {
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      arrange?.call();
      Get.put(HomeController(tokens));
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(auditApp(child: const HomeView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('offline: the carousel placeholder stays (no default card), with retry above', (tester) async {
      await openHome(tester, arrange: () => FakeApi.failing.add('*'));
      expect(find.byType(FeaturedCourseCarouselPlaceholder), findsOneWidget);
      expect(find.text('start_journey'.tr), findsNothing, reason: 'no default card before the server answers');
      expect(find.byType(GuestSignUpBanner), findsNothing);
      expect(find.text('retry_action'.tr), findsOneWidget);
      await close(tester);
    });

    testWidgets('the server has no open course: the default card', (tester) async {
      await openHome(
        tester,
        arrange: () {
          FakeApi.failing.add('fetchHomepage');
          replaceFake<CourseRepository>(_ClosedCourses(Get.find<ApiClient>()));
        },
      );
      expect(find.text('start_journey'.tr), findsOneWidget);
      expect(find.byType(FeaturedCourseCarouselPlaceholder), findsNothing);
      await close(tester);
    });

    testWidgets('open courses: the carousel', (tester) async {
      await openHome(tester);
      expect(find.byType(FeaturedCourseCarousel), findsOneWidget);
      expect(find.text('start_journey'.tr), findsNothing);
      expect(find.byType(GuestSignUpBanner), findsNothing);
      await close(tester);
    });
  });
}
