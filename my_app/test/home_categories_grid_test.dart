import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/modules/home/widgets/home_categories_grid.dart';

List<CategoryModel> _categories(int n) => [
  for (var i = 1; i <= n; i++) CategoryModel(id: i, nameAr: 'Category $i', nameEn: 'Category $i', coursesCount: i),
];

Widget _host(List<CategoryModel> categories, {ValueChanged<CategoryModel>? onOpen, VoidCallback? onAll}) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: HomeCategoriesGrid(categories: categories, onOpenCategory: onOpen ?? (_) {}, onShowAll: onAll ?? () {}),
      ),
    ),
  );
}

void main() {
  testWidgets('more than 8: top 7 by course count plus a "+X" card', (tester) async {
    await tester.pumpWidget(_host(_categories(40)));

    // الأكثر دورات أولاً (40 … 34)، والأقل لا يظهر.
    for (var i = 40; i >= 34; i--) {
      expect(find.text('Category $i'), findsOneWidget);
    }
    expect(find.text('Category 33'), findsNothing);
    expect(find.text('+33'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('8 or fewer: all shown, no "+X" card', (tester) async {
    await tester.pumpWidget(_host(_categories(8)));

    for (var i = 1; i <= 8; i++) {
      expect(find.text('Category $i'), findsOneWidget);
    }
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('taps open the category or the full list', (tester) async {
    CategoryModel? opened;
    var allTaps = 0;
    await tester.pumpWidget(_host(_categories(12), onOpen: (c) => opened = c, onAll: () => allTaps++));

    await tester.tap(find.text('Category 12'));
    await tester.tap(find.text('+5'));

    expect(opened?.id, 12);
    expect(allTaps, 1);
  });

  testWidgets('long names fit a narrow phone without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host([
        for (var i = 1; i <= 9; i++)
          CategoryModel(
            id: i,
            nameAr: 'الذكاء الاصطناعي وتعلم الآلة',
            nameEn: 'Artificial Intelligence',
            coursesCount: i,
          ),
      ]),
    );
    expect(tester.takeException(), isNull);
  });
}
