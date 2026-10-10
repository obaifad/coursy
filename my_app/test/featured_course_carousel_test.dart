import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/modules/home/widgets/featured_course_carousel.dart';

import 'layout/sample_data.dart';

CourseModel _course(int id, {String? discount, String price = '100000', bool featured = true}) {
  return CourseModel.fromJson({
    'id': id,
    'title_ar': 'دورة رقم $id',
    'title_en': 'Course $id',
    'price': price,
    if (discount != null) 'discount_price': discount,
    'is_featured': featured ? 1 : 0,
    'average_rating': '4.5',
  });
}

Widget _host(List<CourseModel> courses, {ValueChanged<CourseModel>? onOpen}) {
  return MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FeaturedCourseCarousel(courses: courses, onOpenCourse: onOpen, interval: const Duration(seconds: 4)),
      ),
    ),
  );
}

/// أي بطاقة تظهر في منتصف الشاشة الآن.
int _centeredCourseId(WidgetTester tester) {
  final center = tester.getCenter(find.byType(FeaturedCourseCarousel)).dx;
  final cards = find.textContaining('دورة رقم');
  int? best;
  var bestDistance = double.infinity;
  for (final element in cards.evaluate()) {
    final text = (element.widget as Text).data!;
    final id = int.parse(text.split(' ').last);
    final distance = (tester.getCenter(find.byWidget(element.widget)).dx - center).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = id;
    }
  }
  return best!;
}

void main() {
  final courses = [_course(1), _course(2), _course(3)];

  testWidgets('auto-advances to the next course after the interval', (tester) async {
    await tester.pumpWidget(_host(courses));
    final first = _centeredCourseId(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(_centeredCourseId(tester), isNot(first));
  });

  testWidgets('pauses while the card is touched and resumes after release', (tester) async {
    await tester.pumpWidget(_host(courses, onOpen: (_) {}));
    final first = _centeredCourseId(tester);

    final gesture = await tester.startGesture(tester.getCenter(find.byType(FeaturedCourseCarousel)));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(_centeredCourseId(tester), first, reason: 'held card must not advance');

    await gesture.up();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(_centeredCourseId(tester), isNot(first), reason: 'resumes after release');
  });

  testWidgets('tapping a card or its buttons opens that course', (tester) async {
    final opened = <int>[];
    await tester.pumpWidget(_host(courses, onOpen: (c) => opened.add(c.id)));
    final shown = _centeredCourseId(tester);

    await tester.tap(find.text('book_now').hitTestable().first);
    await tester.pump();
    await tester.tap(find.text('course_details').hitTestable().first);
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(FeaturedCourseCarousel)) + const Offset(0, -40));
    await tester.pump();

    expect(opened, [shown, shown, shown]);
  });

  testWidgets('a single course shows no dots and never auto-scrolls', (tester) async {
    await tester.pumpWidget(_host([_course(7)]));

    expect(find.byType(AnimatedContainer), findsNothing);
    await tester.pump(const Duration(seconds: 12));
    expect(_centeredCourseId(tester), 7);
  });

  testWidgets('shows one dot per course and nothing for an empty list', (tester) async {
    await tester.pumpWidget(_host(courses));
    expect(find.byType(AnimatedContainer), findsNWidgets(3));

    await tester.pumpWidget(_host(const []));
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('renders the audit sample courses (long titles, discount) without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(sampleCourses()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  test('discountPercent is derived from the real prices', () {
    expect(_course(1, price: '1500000', discount: '1200000').discountPercent, 20);
    expect(_course(1, price: '100000').discountPercent, isNull);
    expect(_course(1, price: '100000', discount: '100000').discountPercent, isNull);
    expect(_course(1, price: '100000', discount: '0').discountPercent, isNull);
  });
}
