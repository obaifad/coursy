import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/data/repositories/home_repository.dart';
import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/home/widgets/home_categories_grid.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/modules/notifications/controllers/notifications_controller.dart';
import 'package:my_app/modules/notifications/views/notifications_view.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/widgets/app_skeletons.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';
import 'package:my_app/widgets/profile_avatar.dart';
import 'package:my_app/theme/app_fonts.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// تحسينات الواجهة المتفق عليها (F8–F11).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    String locale = 'ar',
    double height = 780,
    double dpr = 1,
  }) async {
    tester.view.physicalSize = Size(360 * dpr, height * dpr);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: child, locale: locale, scale: 1, boundaryKey: GlobalKey()));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> rootSetup({required bool loggedIn, required int tab}) async {
    final tokens = await registerFakes(loggedIn: loggedIn, locale: 'ar');
    Get.put(HomeController(tokens));
    Get.put(CoursesController());
    Get.put(InstitutesController());
    Get.put(MyCoursesController());
    Get.put(RootController()).currentIndex.value = tab;
  }

  group('F8 institute info tab', () {
    Future<void> open(WidgetTester tester) async {
      Get.put(InstituteDetailsController(), tag: 't').institute.value = sampleInstitutes().first;
      // طويلة كي تُبنى عناصر التبويب كلها (القائمة تبني ما يظهر فقط).
      await pump(tester, const InstituteDetailsView(controllerTag: 't'), height: 1800);
    }

    testWidgets('shows the first 3 courses after "About"; "View all" opens the Courses tab', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      await open(tester);

      final info = find.byType(TabBarView);
      final rows = find.descendant(of: info, matching: find.byType(CourseRowCard));
      expect(rows, findsNWidgets(3), reason: '4 courses loaded, 3 shown');
      final about = tester.getRect(find.text('about_institute'.tr));
      expect(tester.getRect(rows.first).top, greaterThan(about.bottom), reason: 'after "About the institute"');

      await tester.tap(find.descendant(of: info, matching: find.text('show_all'.tr)));
      await tester.pumpAndSettle();
      final tabs = DefaultTabController.of(tester.element(find.byType(TabBarView)));
      expect(tabs.index, 1, reason: '"View all" opens the Courses tab');
    });

    testWidgets('no courses: nothing extra on the info tab', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      FakeApi.failing.add('fetchInstituteCourses');
      await open(tester);
      final info = find.byType(TabBarView);
      expect(find.descendant(of: info, matching: find.byType(CourseRowCard)), findsNothing);
      expect(find.descendant(of: info, matching: find.byType(AppSectionHeader)), findsNothing);
    });
  });

  testWidgets('F9 notifications use the brand header with the same actions', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(NotificationsController());
    await pump(tester, const NotificationsView());
    final bar = find.byType(AppBrandSliverAppBar);
    expect(bar, findsOneWidget);
    expect(tester.widget<AppBrandSliverAppBar>(bar).title, 'notifications'.tr);
    expect(tester.widget<AppBrandSliverAppBar>(bar).badge, isNull, reason: 'no invented content');
    expect(find.byTooltip('refresh'.tr), findsOneWidget);
    expect(find.byType(NotificationCard), findsWidgets);
  });

  group('F10 home', () {
    testWidgets('banner dots sit close to "Categories" (was ~37 px)', (tester) async {
      await rootSetup(loggedIn: true, tab: 2);
      await pump(tester, const RootView());
      final dot = tester.getRect(
        find.descendant(of: find.byKey(const ValueKey('carousel-dot-0')), matching: find.byType(DecoratedBox)).first,
      );
      final title = tester.getRect(find.text('section_categories'.tr));
      expect(title.top - dot.bottom, lessThanOrEqualTo(24));
      expect(title.top - dot.bottom, greaterThanOrEqualTo(16), reason: 'still a clear gap');
    });

    testWidgets('long category names wrap to two lines at full size; counts stay aligned', (tester) async {
      final categories = [
        CategoryModel(id: 1, nameAr: 'الذكاء الاصطناعي وتعلم الآلة', nameEn: 'AI', coursesCount: 9),
        CategoryModel(id: 2, nameAr: 'اللغات', nameEn: 'Languages', coursesCount: 8),
        CategoryModel(id: 3, nameAr: 'المهارات الشخصية', nameEn: 'Soft skills', coursesCount: 7),
        CategoryModel(id: 4, nameAr: 'تصميم', nameEn: 'Design', coursesCount: 6),
      ];
      await pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: HomeCategoriesGrid(categories: categories, onOpenCategory: (_) {}, onShowAll: () {}),
        ),
      );
      final long = find.text('الذكاء الاصطناعي وتعلم الآلة');
      expect(find.ancestor(of: long, matching: find.byType(FittedBox)), findsNothing, reason: 'not shrunk to fit');
      final text = tester.widget<Text>(long);
      expect(text.maxLines, 2);
      expect(text.style?.fontSize, AppTextSize.sm);
      double textHeight(Finder f) {
        final p = tester.renderObject<RenderParagraph>(f);
        return p.getMaxIntrinsicHeight(p.size.width);
      }

      expect(textHeight(long), greaterThan(textHeight(find.text('تصميم')) * 1.5), reason: 'wraps to a 2nd line');
      final counts = [for (final c in categories) tester.getRect(find.text(pluralTr('category_courses_count', c.coursesCount))).top];
      expect(counts.toSet(), hasLength(1), reason: 'course counts in a row share one line');
    });

    testWidgets('a word wider than the column shrinks a little instead of breaking mid-word', (tester) async {
      final categories = [
        CategoryModel(id: 1, nameAr: 'البرمجة', nameEn: 'Programming', coursesCount: 9),
        CategoryModel(id: 2, nameAr: 'إدارة', nameEn: 'Business, Management & Marketing', coursesCount: 8),
        CategoryModel(id: 3, nameAr: 'لغات', nameEn: 'Languages', coursesCount: 7),
        CategoryModel(id: 4, nameAr: 'تصميم', nameEn: 'Design', coursesCount: 6),
      ];
      Get.locale = const Locale('en');
      await pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: HomeCategoriesGrid(categories: categories, onOpenCategory: (_) {}, onShowAll: () {}),
        ),
        locale: 'en',
        // كثافة شاشة هاتف حقيقية: تقريب البكسلات يغيّر عرض النص قليلاً.
        dpr: 3,
      );
      // أسطر النص المرسوم فعلاً (لا ارتفاع الصندوق الثابت).
      int renderedLines(String text) {
        final p = tester.renderObject<RenderParagraph>(find.text(text));
        final boxes = p.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length));
        return boxes.map((b) => b.top.round()).toSet().length;
      }

      expect(renderedLines('Programming'), 1, reason: '"Programming" broke in the middle of the word');
      expect(tester.widget<Text>(find.text('Programming')).style!.fontSize, greaterThan(AppTextSize.sm * 0.8));
      expect(renderedLines('Business, Management & Marketing'), 2);
      expect(tester.widget<Text>(find.text('Design')).style!.fontSize, AppTextSize.sm, reason: 'others full size');
    });

    testWidgets('home skeleton shows the categories grid at the page position', (tester) async {
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      Get.delete<HomeRepository>(force: true);
      final home = Get.put<HomeRepository>(_HeldHome(Get.find<ApiClient>())) as _HeldHome;
      Get.put(HomeController(tokens));
      Get.put(CoursesController());
      Get.put(InstitutesController());
      Get.put(MyCoursesController());
      Get.put(RootController()).currentIndex.value = 2;
      await pump(tester, const RootView());
      expect(find.byType(AppHomeSkeleton), findsOneWidget);
      final skeletonGrid = find.descendant(of: find.byType(AppHomeSkeleton), matching: find.byType(HomeCategoriesGrid));
      expect(skeletonGrid, findsOneWidget, reason: 'skeleton drew a short rail instead of the grid');
      final skeletonTop = tester.getRect(skeletonGrid).top;
      final skeletonHeight = tester.getSize(skeletonGrid).height;

      home.response.complete(
        HomePayload(
          courses: sampleCourses(),
          suggestedCourses: sampleCourses(),
          institutes: sampleInstitutes(),
          categories: sampleCategories(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(AppHomeSkeleton), findsNothing);
      final grid = find.byType(HomeCategoriesGrid);
      expect(tester.getRect(grid).top, closeTo(skeletonTop, 1));
      // الهيكل صفّان (8 تصنيفات)؛ بيانات الاختبار 3 تصنيفات: صف واحد، وأحد أسمائها على سطرين.
      expect(skeletonHeight, greaterThan(tester.getSize(grid).height), reason: 'a grid, not a 56 px rail');
    });
  });

  group('F11 guest profile', () {
    testWidgets('shorter header and contact / privacy / terms rows', (tester) async {
      await rootSetup(loggedIn: false, tab: 4);
      await pump(tester, const RootView());
      final avatar = find.byType(ProfileAvatar);
      expect(tester.widget<ProfileAvatar>(avatar).size, lessThan(88), reason: 'guest header is shorter');
      for (final key in ['contact_us', 'privacy_policy', 'terms_of_use']) {
        await tester.scrollUntilVisible(find.text(key.tr), 100, scrollable: find.byType(Scrollable).first);
        expect(find.text(key.tr), findsOneWidget, reason: '$key row for guests');
      }
    });
  });
}

/// /homepage يرد حين يقرر الاختبار، بلا نسخة محفوظة (أول تشغيل).
class _HeldHome extends HomeRepository {
  _HeldHome(super.client);

  final response = Completer<HomePayload?>();

  @override
  Future<HomePayload?> fetchHomepage() => response.future;

  @override
  HomePayload? cachedHomepage() => null;
}
