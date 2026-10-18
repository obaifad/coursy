import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/navigation/app_page_transition.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/views/category_courses_view.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/widgets/course_favorite_button.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

class _CountingCourses extends CourseRepository {
  _CountingCourses(super.client, super.rating);

  int details = 0;
  int pages = 0;

  @override
  Future<CourseModel> fetchCourseById(int id) async {
    details++;
    return sampleCourses().firstWhere((c) => c.id == id);
  }

  @override
  Future<List<ScheduleModel>> fetchCourseSchedules(int courseId) async => [];

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    pages++;
    return PaginatedResult(items: sampleCourses(), currentPage: 1, lastPage: 1, total: 4, hasMore: false);
  }
}

/// انتقال Hero أخف: بلا تكبير للصفحة، بلا تمويه حقيقي لزر القلب أثناء الحركة، والطلبات بعد الحركة.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    RouteMotion.resetForTest();
    Get.reset();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the page transition is a fade with a short rise (no scale, no Hero)', (tester) async {
    final animation = AnimationController(vsync: const TestVSync(), value: 0.5);
    addTearDown(animation.dispose);
    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = AppPageTransition().buildTransition(
            context,
            null,
            null,
            animation,
            kAlwaysDismissedAnimation,
            const SizedBox(),
          );
          return built;
        },
      ),
    );
    expect(built, isA<FadeTransition>());
    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byType(ScaleTransition), findsNothing);
  });

  testWidgets('the details-page heart drops its real blur while a page moves', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [RouteMotionObserver()],
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CourseFavoriteButton(courseId: 1, diameter: 38, blurBackground: true),
                TextButton(
                  onPressed: () => Get.to<void>(() => const Scaffold(body: Text('next'))),
                  child: const Text('go'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(BackdropFilter), findsOneWidget, reason: 'settled: real glass');

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BackdropFilter, skipOffstage: false), findsNothing, reason: 'moving: flat fill');

    await settle(tester);
    Get.back<void>();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BackdropFilter), findsNothing);
    await settle(tester);
    expect(find.byType(BackdropFilter), findsOneWidget, reason: 'back and settled: glass again');
  });

  testWidgets('course details waits for the opening animation before any request', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _CountingCourses(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    Get.delete<CourseRepository>(force: true);
    Get.put<CourseRepository>(repo);
    final seed = sampleCourses().first;

    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [RouteMotionObserver()],
        home: Scaffold(
          body: TextButton(
            onPressed: () => Get.to<void>(
              () => Builder(
                builder: (context) {
                  Get.put(CourseDetailsController(), tag: 'perf');
                  return const Scaffold(body: Text('details'));
                },
              ),
              arguments: seed,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final controller = Get.find<CourseDetailsController>(tag: 'perf');
    expect(controller.course.value?.id, seed.id, reason: 'the card data is shown at once');
    expect(controller.isLoading.value, isFalse, reason: 'seeded: no skeleton');
    expect(repo.details, 0, reason: 'no request while the page (and the Hero) is moving');

    await settle(tester);
    expect(repo.details, greaterThanOrEqualTo(1), reason: 'fetched once the animation ended');
  });

  // كان RouteSettle يقرأ حالة أنيميشن المسار، ومسار GetX يُبنى أول مرة بحالة «مكتملة» فيجري العمل فوراً.
  testWidgets('the category page also waits (regression: RouteSettle used to run at once)', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _CountingCourses(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    Get.delete<CourseRepository>(force: true);
    Get.put<CourseRepository>(repo);

    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [RouteMotionObserver()],
        home: Scaffold(
          body: TextButton(
            onPressed: () => Get.to<void>(
              () => Builder(
                builder: (context) {
                  Get.put(CategoryCoursesController(), tag: 'cat');
                  return const Scaffold(body: Text('category'));
                },
              ),
              arguments: <String, dynamic>{'id': 3, 'name': 'البرمجة'},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(repo.pages, 0, reason: 'skeleton while moving, no request yet');
    await settle(tester);
    expect(repo.pages, 1);
  });

  // Hero أُزيل من التطبيق كله: لا صورة طائرة بين البطاقة والتفاصيل.
  testWidgets('no Hero in a course grid nor on the course page', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.routing.args = <String, dynamic>{'id': 3, 'name': 'البرمجة'};
    Get.put(CategoryCoursesController());
    await tester.pumpWidget(
      auditApp(child: const CategoryCoursesView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Hero), findsNothing);

    final c = Get.put(CourseDetailsController(), tag: 'no-hero');
    c.course.value = sampleCourses().first;
    await tester.pumpWidget(
      auditApp(
        child: const CourseDetailsView(controllerTag: 'no-hero'),
        locale: 'ar',
        scale: 1,
        boundaryKey: GlobalKey(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Hero), findsNothing);
  });
}
