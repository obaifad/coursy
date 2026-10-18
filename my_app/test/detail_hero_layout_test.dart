import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// رأس صفحتَي المعهد والمدرّس: الشعار والاسم بين شريط الأدوات وشريط التبويبات بفراغ كافٍ،
/// مهما كان ارتفاع شريط الحالة (24 قديم، 36 و48 ذوا شق) وحجم الخط.
void main() {
  setUpAll(loadAuditFonts);

  const avatarKey = ValueKey('hero-avatar');
  const tabsKey = ValueKey('hero-tabs');
  const nameText = 'مركز الشام التعليمي للتدريب المهني المتقدم والدورات الاحترافية';

  Future<void> pump(WidgetTester tester, {required double statusBar, double textScale = 1}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              padding: EdgeInsets.only(top: statusBar),
              viewPadding: EdgeInsets.only(top: statusBar),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Builder(
              builder: (context) => Scaffold(
                body: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverAppBar(
                      expandedHeight: AppDetailHero.expandedHeight(context, avatarSize: 88),
                      pinned: true,
                      title: const Text('عنوان الشريط'),
                      flexibleSpace: FlexibleSpaceBar(
                        background: AppDetailHeroContent(
                          name: nameText,
                          background: const ColoredBox(color: Colors.purple),
                          avatar: const SizedBox.square(key: avatarKey, dimension: 88),
                        ),
                      ),
                      bottom: const PreferredSize(
                        preferredSize: Size.fromHeight(AppDetailHero.tabBarHeight),
                        child: SizedBox(key: tabsKey, height: AppDetailHero.tabBarHeight),
                      ),
                    ),
                  ],
                  body: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final statusBar in [24.0, 36.0, 48.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('status bar ${statusBar.toInt()}dp, text scale $scale: logo and name clear of toolbar and tabs', (
        tester,
      ) async {
        await pump(tester, statusBar: statusBar, textScale: scale);
        expect(tester.takeException(), isNull);

        final avatar = tester.getRect(find.byKey(avatarKey));
        final name = tester.getRect(find.text(nameText));
        final tabs = tester.getRect(find.byKey(tabsKey));
        final toolbarBottom = statusBar + kToolbarHeight;

        expect(avatar.top - toolbarBottom, greaterThanOrEqualTo(8), reason: 'logo clear of the toolbar title');
        expect(name.top, greaterThanOrEqualTo(avatar.bottom), reason: 'name below the logo');
        expect(tabs.top - name.bottom, greaterThanOrEqualTo(8), reason: 'name clear of the tab bar');
        expect(avatar.center.dx, closeTo(180, 1), reason: 'centred');
      });
    }
  }
}
