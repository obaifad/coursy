import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:my_app/core/data/repositories/home_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/core/storage/home_cache.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/home/views/home_view.dart';
import 'package:my_app/modules/home/widgets/featured_course_carousel.dart';
import 'package:my_app/modules/home/widgets/home_status_banner.dart';
import 'package:my_app/widgets/app_skeletons.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// إكمال التقييم يتأخر حتى يُكمله الاختبار — مثل تحميل كل صفحات المعاهد على شبكة بطيئة.
class _SlowRating extends CourseRatingService {
  _SlowRating(super.client);

  final gate = Completer<void>();

  @override
  Future<List<CourseModel>> enrich(List<CourseModel> courses) async {
    await gate.future;
    return [for (final c in courses) c.copyWith(rating: 4.9)];
  }

  @override
  Future<List<InstituteModel>> enrichInstitutes(List<InstituteModel> institutes) async => institutes;
}

/// /homepage يتحكم الاختبار بوقت رده، ومعه رد محفوظ اختياري (الكاش).
class _ControlledHome extends HomeRepository {
  _ControlledHome(super.client, {this.cached});

  final HomePayload? cached;
  final response = Completer<HomePayload?>();

  @override
  Future<HomePayload?> fetchHomepage() => response.future;

  @override
  HomePayload? cachedHomepage() => cached;
}

HomePayload _payload() => HomePayload(
  courses: sampleCourses(),
  suggestedCourses: sampleCourses().reversed.toList(),
  institutes: sampleInstitutes(),
  categories: sampleCategories(),
);

Future<(HomeController, _ControlledHome, _SlowRating)> _setUp({required bool loggedIn, HomePayload? cached}) async {
  final tokens = await registerFakes(loggedIn: loggedIn, locale: 'ar');
  final client = Get.find<ApiClient>();
  Get.delete<CourseRatingService>(force: true);
  final rating = Get.put<CourseRatingService>(_SlowRating(client)) as _SlowRating;
  Get.delete<HomeRepository>(force: true);
  final home = Get.put<HomeRepository>(_ControlledHome(client, cached: cached)) as _ControlledHome;
  final controller = Get.put(HomeController(tokens));
  return (controller, home, rating);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAuditFonts);
  setUp(Get.reset);

  group('banner courses do not wait for rating enrichment', () {
    testWidgets('the banner fills as soon as /homepage answers, then picks up the enriched ratings', (tester) async {
      final (c, home, rating) = await _setUp(loggedIn: true);
      expect(c.bannerCourses, isEmpty);

      home.response.complete(_payload());
      await tester.pump();
      expect(c.courses.map((x) => x.id), sampleCourses().map((x) => x.id));
      expect(c.bannerCourses, isNotEmpty, reason: 'no wait for the institutes cache');
      expect(c.courses.first.rating, isNot(4.9));

      rating.gate.complete();
      await tester.pump();
      await tester.pump();
      expect(c.courses.every((x) => x.rating == 4.9), isTrue);
    });

    testWidgets('enriched data is never replaced by a raw copy on refresh', (tester) async {
      final (c, home, rating) = await _setUp(loggedIn: true);
      home.response.complete(_payload());
      rating.gate.complete();
      await tester.pump();
      await tester.pump();
      expect(c.courses.first.rating, 4.9);

      // التحديث يجلب /courses: لا وميض لنسخة غير مكمّلة بين الطلب والإكمال.
      unawaited(c.loadHome(forceRefresh: true));
      await tester.pump();
      expect(c.courses.first.rating, 4.9);
      await tester.pump(const Duration(milliseconds: 50));
      expect(c.courses.first.rating, 4.9);
    });

    test('banner order: featured, then discounted, then by rating; registration open only', () async {
      final (c, home, rating) = await _setUp(loggedIn: true);
      rating.gate.complete();
      home.response.complete(_payload());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final ids = c.bannerCourses.map((x) => x.id).toList();
      expect(ids.first, 1, reason: 'featured first');
      expect(ids, isNot(contains(4)), reason: 'registration deadline passed');
    });
  });

  group('home paints from the on-device copy', () {
    testWidgets('a cached homepage fills Home before the network answers', (tester) async {
      final (c, _, _) = await _setUp(loggedIn: true, cached: _payload());
      expect(c.isLoading.value, isTrue);
      expect(c.categories, isNotEmpty);
      expect(c.courses, isNotEmpty);
      expect(c.bannerCourses, isNotEmpty);
    });

    for (final loggedIn in [true, false]) {
      final name = loggedIn ? 'student' : 'guest';
      testWidgets('first frame: the right banner, no skeleton ($name)', (tester) async {
        await _setUp(loggedIn: loggedIn, cached: _payload());
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Get.locale = const Locale('ar');
        await tester.pumpWidget(auditApp(child: const HomeView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));

        expect(find.byType(AppHomeSkeleton), findsNothing);
        if (loggedIn) {
          expect(find.byType(FeaturedCourseCarousel), findsOneWidget);
          expect(find.byType(GuestSignUpBanner), findsNothing);
        } else {
          expect(find.byType(GuestSignUpBanner), findsOneWidget);
          expect(find.byType(FeaturedCourseCarousel), findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('a cached copy that the network fails to refresh still triggers the other requests', (tester) async {
      final (c, home, rating) = await _setUp(loggedIn: false, cached: HomePayload(categories: sampleCategories()));
      rating.gate.complete();
      home.response.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // /courses (الفيك) جاء بالدورات رغم أن الكاش لم يكن فارغاً.
      expect(c.courses.map((x) => x.id), sampleCourses().map((x) => x.id));
    });
  });

  group('no flash of the wrong banner while loading', () {
    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.locale = const Locale('ar');
      await tester.pumpWidget(auditApp(child: const HomeView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    }

    testWidgets('student, no saved copy: categories alone keep the skeleton (no default card)', (tester) async {
      final (c, _, _) = await _setUp(loggedIn: true);
      // التصنيفات وصلت والدورات لم تصل بعد (الرد الأول جزئي).
      c.categories.assignAll(sampleCategories());
      await pumpHome(tester);

      expect(find.byType(AppHomeSkeleton), findsOneWidget);
      expect(find.byType(FeaturedCourseCarouselPlaceholder), findsOneWidget, reason: 'carousel-sized banner slot');
      expect(find.byType(GuestSignUpBanner), findsNothing);
      expect(find.text('smart_suggestions'.tr), findsNothing, reason: 'the default hero card must not flash');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('student: courses arrived but none fits the banner yet -> placeholder, not the default card', (
      tester,
    ) async {
      final (c, _, _) = await _setUp(loggedIn: true);
      final closed = sampleCourses().where((x) => !x.isRegistrationOpen).toList();
      expect(closed, isNotEmpty);
      c.courses.assignAll(closed);
      c.categories.assignAll(sampleCategories());
      expect(c.bannerCourses, isEmpty);
      await pumpHome(tester);

      expect(find.byType(AppHomeSkeleton), findsNothing);
      expect(find.byType(FeaturedCourseCarouselPlaceholder), findsOneWidget);
      expect(find.text('smart_suggestions'.tr), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the placeholder is exactly as tall as the carousel it stands for', (tester) async {
      Get.locale = const Locale('ar');
      late double placeholder;
      late double carousel;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                placeholder = FeaturedCourseCarouselPlaceholder.heightOf(context);
                return Column(
                  children: [
                    const FeaturedCourseCarouselPlaceholder(),
                    FeaturedCourseCarousel(courses: sampleCourses().take(3).toList(), onOpenCourse: (_) {}),
                  ],
                );
              },
            ),
          ),
        ),
      );
      carousel = tester.getSize(find.byType(FeaturedCourseCarousel)).height;
      expect(tester.getSize(find.byType(FeaturedCourseCarouselPlaceholder)).height, placeholder);
      expect(placeholder, closeTo(carousel, 0.5));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('home cache storage', () {
    late Directory dir;
    late HomeCache cache;
    var container = 0;

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('home_cache_test');
      // GetStorage يسأل path_provider عن مجلد التطبيق (ولا إضافة له في الاختبار)، ويكتب على القرص بعد
      // انتهاء write — فيبقى البديل والمجلد طوال المجموعة كي لا تفشل كتابة متأخرة.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      );
    });

    setUp(() async {
      final box = GetStorage('home_cache_test_${container++}', dir.path);
      await box.initStorage;
      cache = HomeCache(box: box);
    });

    test('payloads are kept per language and per audience', () async {
      await cache.writePayload('ar', 'guest', {'categories': []});
      await cache.writePayload('ar', 'student_7', {'courses': []});
      expect(cache.readPayload('ar', 'guest'), {'categories': []});
      expect(cache.readPayload('ar', 'student_7'), {'courses': []});
      expect(cache.readPayload('en', 'guest'), isNull);
      expect(cache.readPayload('ar', 'student_8'), isNull);
    });

    test('logging out drops student copies and keeps the public guest copy', () async {
      await cache.writePayload('ar', 'guest', {'categories': []});
      await cache.writePayload('ar', 'student_7', {'courses': []});
      await cache.clearStudentEntries();
      expect(cache.readPayload('ar', 'guest'), isNotNull);
      expect(cache.readPayload('ar', 'student_7'), isNull);
    });

    test('the repository parses the stored copy back into the same courses', () async {
      final json = {
        'data': {
          'featured_courses': [
            {'id': 11, 'title_ar': 'فلاتر', 'price': '100000'},
            {'id': 12, 'title_ar': 'تصميم', 'price': '0'},
          ],
          'categories': [
            {'id': 3, 'name_ar': 'البرمجة'},
          ],
        },
      };
      await cache.writePayload('ar', 'guest', json);
      await registerFakes(loggedIn: false, locale: 'ar');
      final repo = HomeRepository(Get.find<ApiClient>(), cache: cache);
      final payload = repo.cachedHomepage();
      expect(payload?.courses.map((c) => c.id), [11, 12]);
      expect(payload?.categories.single.id, 3);
    });
  });
}
