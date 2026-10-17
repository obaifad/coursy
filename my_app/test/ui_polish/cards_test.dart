import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

Future<void> _pump(WidgetTester tester, Widget child, {String locale = 'ar', double width = 360}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Get.locale = Locale(locale);
  await tester.pumpWidget(auditApp(child: child, locale: locale, scale: 1, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(loadAuditFonts);
  setUp(Get.reset);

  group('poster course card', () {
    for (final locale in ['ar', 'en']) {
      testWidgets('title sits on the cover; price and rating sit in the white strip ($locale)', (tester) async {
        final course = sampleCourses().first;
        var taps = 0;
        await _pump(
          tester,
          Center(
            child: SizedBox(
              width: 164,
              child: CoursePosterCard(course: course, onTap: () => taps++),
            ),
          ),
          locale: locale,
        );

        final spec = CourseCardMetrics.posterSpec(164);
        final card = tester.getRect(find.byType(CoursePosterCard));
        expect(card.height, spec.totalHeight);
        final coverBottom = card.top + spec.coverHeight;

        final title = find.text(course.title);
        expect(tester.getRect(title).bottom, lessThanOrEqualTo(coverBottom));
        expect(tester.widget<Text>(title).style?.color, Colors.white);
        expect(tester.widget<Text>(title).style?.fontWeight, FontWeight.w800);

        final price = tester.getRect(find.byType(CoursePriceText));
        final rating = tester.getRect(find.byType(CourseRatingBadge));
        expect(price.top, greaterThanOrEqualTo(coverBottom));
        expect(rating.top, greaterThanOrEqualTo(coverBottom));
        // السعر في جهة البداية والتقييم في جهة النهاية.
        if (locale == 'ar') {
          expect(price.center.dx, greaterThan(rating.center.dx));
        } else {
          expect(price.center.dx, lessThan(rating.center.dx));
        }

        await tester.tap(find.byType(CoursePosterCard));
        expect(taps, 1);
      });
    }

    testWidgets('a course without ratings says so instead of showing grey stars', (tester) async {
      // الخادم أرسل reviews_count = 0: بلا تقييم (ولا يُستعار تقييم المعهد).
      final unrated = CourseModel.fromJson({'id': 9, 'title_ar': 'تصميم', 'price': '0', 'reviews_count': 0});
      await _pump(
        tester,
        Center(
          child: SizedBox(width: 164, child: CoursePosterCard(course: unrated)),
        ),
      );
      expect(find.text('rating_none_short'.tr), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('the poster grid fits every tile without overflow on a 320px phone', (tester) async {
      final courses = sampleCourses();
      await _pump(
        tester,
        Builder(
          builder: (context) => GridView.builder(
            padding: EdgeInsets.all(AppLayout.horizontalPage(context)),
            gridDelegate: AppGridLayouts.posterGridFor(context),
            itemCount: courses.length,
            itemBuilder: (_, i) => CoursePosterCard(course: courses[i]),
          ),
        ),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CoursePosterCard), findsNWidgets(courses.length));
    });
  });

  group('compact row cards', () {
    List<Widget> rows() => [
      CourseRowCard(course: sampleCourses().first, onTap: () {}),
      InstituteListCard(institute: sampleInstitutes().first, onTap: () {}),
      PrivateInstructorListCard(instructor: sampleInstructors().first, onTap: () {}),
    ];

    for (final locale in ['ar', 'en']) {
      testWidgets('rows are 118px tall with the thumbnail on the start edge ($locale)', (tester) async {
        await _pump(
          tester,
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final row in rows()) ...[row, const SizedBox(height: 12)],
            ],
          ),
          locale: locale,
        );
        expect(tester.takeException(), isNull);

        final cards = find.byType(AppRowCard);
        expect(cards, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          final card = tester.getRect(cards.at(i));
          expect(card.height, closeTo(AppRowCard.height, 0.5), reason: 'row $i');
          final thumb = tester.getRect(find.descendant(of: cards.at(i), matching: find.byType(ClipRRect)).first);
          expect(thumb.width, AppRowCard.thumbSize);
          if (locale == 'ar') {
            expect(thumb.right, card.right - AppRowCard.padding);
          } else {
            expect(thumb.left, card.left + AppRowCard.padding);
          }
        }
      });
    }

    testWidgets('course row: duration and rating on the start side, price on the end side', (tester) async {
      final course = sampleCourses().first;
      await _pump(
        tester,
        ListView(
          padding: const EdgeInsets.all(16),
          children: [CourseRowCard(course: course)],
        ),
      );
      final duration = tester.getRect(find.text(course.duration));
      final price = tester.getRect(find.byType(CoursePriceText));
      expect((duration.center.dy - price.center.dy).abs(), lessThan(4));
      expect(price.center.dx, lessThan(duration.center.dx)); // RTL: النهاية يساراً
    });

    testWidgets('rows fit narrow phones and large text without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          auditApp(
            child: ListView(padding: const EdgeInsets.all(16), children: rows()),
            locale: 'ar',
            scale: scale,
            boundaryKey: GlobalKey(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'x$scale');
      }
    });
  });
}
