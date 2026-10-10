import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/app_widgets.dart';

CourseModel _course(Map<String, dynamic> extra) => CourseModel.fromJson({
  'id': 1,
  'title_ar': 'بايثون للمبتدئين',
  'title_en': 'Python for Beginners',
  'price': '500000',
  'average_rating': '4.3',
  ...extra,
});

void main() {
  test('reviewsCount comes from reviews_count or the embedded reviews list', () {
    expect(_course({'reviews_count': 9}).reviewsCount, 9);
    expect(
      _course({
        'reviews': [
          {'rating': 4},
          {'rating': 5},
        ],
      }).reviewsCount,
      2,
    );
    expect(_course({}).reviewsCount, isNull);
    expect(_course({'reviews_count': 9}).copyWith(rating: 4.8).reviewsCount, 9);
  });

  testWidgets('card shows rating count, discount tag and opens on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 270,
              child: CourseCard(course: _course({'reviews_count': 9, 'discount_price': '460000'}), onTap: () => taps++),
            ),
          ),
        ),
      ),
    );

    expect(find.text('(9)'), findsOneWidget);
    expect(find.text('-8%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(CourseCard));
    expect(taps, 1);
  });

  testWidgets('no count and no discount tag when the server sends neither', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 170,
              child: CourseCard(course: _course({}), onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('('), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
