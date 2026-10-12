import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/design_system.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Widget? pinned}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppScrollAwayHeaderView(
            header: const SizedBox(height: 220, child: Center(child: Text('HEADER'))),
            pinned: pinned,
            slivers: [
              SliverList.builder(
                itemCount: 60,
                itemBuilder: (_, i) => SizedBox(height: 80, child: Text('row $i')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double shadowAlpha(WidgetTester tester) {
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
    return box.boxShadow!.first.color.a;
  }

  testWidgets('the header scrolls away and the pinned bar sticks to the top with a shadow', (tester) async {
    await pump(tester, pinned: const SizedBox(height: 44, child: Text('FILTERS')));
    expect(tester.getTopLeft(find.text('FILTERS')).dy, greaterThan(200));
    expect(shadowAlpha(tester), 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('HEADER'), findsNothing);
    // الشريط في أعلى الشاشة (فوقه حشوة الشريط 8 فقط) والبطاقات تمرّ تحته.
    expect(tester.getTopLeft(find.text('FILTERS')).dy, lessThan(12));
    expect(shadowAlpha(tester), greaterThan(0));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('HEADER'), findsOneWidget);
    expect(shadowAlpha(tester), 0);
  });

  testWidgets('without a pinned bar only the header scrolls away', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('HEADER'), findsNothing);
    expect(find.byType(AppPinnedBar), findsNothing);
  });
  testWidgets('hero app bars are white over the hero and dark once it is folded away', (tester) async {
    final seen = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CollapsingHeroScope(
            collapseOffset: 140,
            builder: (context, collapsed) {
              seen.add(collapsed);
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 220,
                    iconTheme: HeroAppBarStyle.icons(collapsed),
                    systemOverlayStyle: HeroAppBarStyle.overlay(collapsed),
                    title: Text('T', style: HeroAppBarStyle.title(collapsed)),
                  ),
                  SliverList.builder(itemCount: 40, itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i'))),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(seen.last, isFalse);
    expect(tester.widget<Text>(find.text('T')).style!.color, Colors.white);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(seen.last, isTrue);
    expect(tester.widget<Text>(find.text('T')).style!.color, isNot(Colors.white));
  });
}
