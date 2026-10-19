import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/courses_views.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/favorites/views/favorites_view.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/theme/app_fonts.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';
import 'package:my_app/widgets/filter_chips.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// الرأس البنفسجي المضغوط (≈104px: سطر واحد للعنوان والعدّاد، بلا سطر فرعي) وصفحة الدورات: الترتيب
/// أيقونة في صف التصنيفات بلا عنوان «التصنيف».
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, Widget screen, {double scale = 1, String locale = 'ar'}) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: screen, locale: locale, scale: scale, boundaryKey: GlobalKey()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  double headerHeight(WidgetTester tester) => tester.getRect(find.byType(AppBar)).height;

  group('compact header', () {
    Widget scene({String? badge, VoidCallback? onBack}) => CustomScrollView(
      slivers: [
        AppBrandSliverAppBar(title: 'كل الدورات', badge: badge, onBack: onBack),
        SliverList.builder(itemCount: 30, itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i'))),
      ],
    );

    testWidgets('is 104px tall at the normal text size (was ~165)', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      await pump(tester, scene(badge: '4 دورات'));
      expect(headerHeight(tester), 104);
    });

    testWidgets('the title and the counter share one row', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      await pump(tester, scene(badge: '4 دورات'));
      final title = tester.getRect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'كل الدورات' && w.style?.fontSize == AppTextSize.display),
      );
      final badge = tester.getRect(find.text('4 دورات'));
      expect((title.center.dy - badge.center.dy).abs(), lessThan(8), reason: 'same row');
      // العنوان في بداية السطر (يمين بالعربية) والعدّاد في نهايته.
      expect(title.right, greaterThan(badge.right));
    });

    testWidgets('the height does not change when the counter arrives', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      await pump(tester, scene());
      final before = headerHeight(tester);
      await pump(tester, scene(badge: '4 دورات'));
      expect(headerHeight(tester), before);
    });

    testWidgets('grows with the text size instead of overflowing', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      await pump(tester, scene(badge: '4 دورات'), scale: 1.3);
      expect(tester.takeException(), isNull);
      expect(headerHeight(tester), greaterThan(104));
    });
  });

  group('screens use it', () {
    Future<void> check(WidgetTester tester, Widget screen, List<String> gone) async {
      await pump(tester, screen);
      expect(headerHeight(tester), inInclusiveRange(104, 105));
      for (final key in gone) {
        expect(find.text(key.tr), findsNothing, reason: key);
      }
    }

    testWidgets('courses header is ~104px with no sub-title', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(CoursesController());
      await check(tester, const CoursesView(), ['browse_courses']);
    });

    testWidgets('institutes header is ~104px with no sub-title', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(InstitutesController());
      await check(tester, const InstitutesView(), ['institutes_subtitle']);
    });

    testWidgets('favorites header is ~104px with no sub-title', (tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(FavoritesController());
      await check(tester, const FavoritesView(), ['favorites_subtitle']);
    });
  });

  group('Courses page filters', () {
    Future<void> openCourses(WidgetTester tester) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(CoursesController());
      await pump(tester, const CoursesView());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 400));
    }

    // المربع المرئي (44) داخل مساحة اللمس (48).
    Rect sortSquare(WidgetTester tester) =>
        tester.getRect(find.descendant(of: find.byType(CourseSortButton), matching: find.byType(Material)).first);

    testWidgets('no «category» label and no separate sort row; sort is one icon in the chips row', (tester) async {
      await openCourses(tester);
      expect(find.text('filter_categories'.tr), findsNothing);
      expect(find.text('sort_by'.tr), findsNothing, reason: 'the old «Sort by» label row is gone');
      expect(find.byType(CourseSortDropdown), findsNothing);
      expect(find.byType(CourseSortButton), findsOneWidget);

      final chips = tester.getRect(find.byType(HorizontalCategoryFilters));
      final sort = sortSquare(tester);
      expect((chips.center.dy - sort.center.dy).abs(), lessThan(2), reason: 'same row');
      expect(sort.width, 44);
      expect(tester.getSize(find.byType(CourseSortButton)), const Size(48, 48), reason: 'touch area');
      // الزر أول الصف عند حافة البداية (يمين بالعربية) وقبل التصنيفات، بهامش الصفحة، بلا تداخل معها.
      expect(sort.right, 360 - 16, reason: 'rests on the right gutter in Arabic');
      expect(chips.right, lessThanOrEqualTo(sort.left), reason: 'the chips start after the button');
      expect(sort.left - chips.right, lessThanOrEqualTo(8 + 0.5));
    });

    testWidgets('English (LTR): the button rests on the left gutter, before the chips', (tester) async {
      await registerFakes(loggedIn: true, locale: 'en');
      Get.put(CoursesController());
      await pump(tester, const CoursesView(), locale: 'en');
      final chips = tester.getRect(find.byType(HorizontalCategoryFilters));
      final sort = sortSquare(tester);
      expect(sort.left, 16);
      expect(chips.left, greaterThanOrEqualTo(sort.right));
    });

    testWidgets('the first card starts right under the filters row', (tester) async {
      await openCourses(tester);
      final sort = tester.getRect(find.byType(CourseSortButton));
      final firstCard = tester.getRect(find.byType(CourseAuroraCard).first);
      expect(firstCard.top, lessThan(sort.bottom + 40));
    });

    testWidgets('choosing a sort option from the button sorts the list and marks the button', (tester) async {
      await openCourses(tester);
      final c = Get.find<CoursesController>();
      expect(c.selectedSort.value, CourseSortOption.newest);
      await tester.tap(find.byType(CourseSortButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CourseSortOption.priceLow.labelKey.tr).last);
      await tester.pumpAndSettle();
      expect(c.selectedSort.value, CourseSortOption.priceLow);
    });
  });
}
