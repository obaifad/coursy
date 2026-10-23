import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/app_skeletons.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// هياكل التحميل بلافندر العلامة (لا الرمادي الافتراضي)، وبطاقة Aurora الهيكلية على شكل البطاقة الحقيقية
/// (غلاف يلمع + لوح أبيض بأسطر)، وصورة الشبكة بخلفية انتظار بدل فراغ.
void main() {
  setUpAll(loadAuditFonts);

  group('theme', () {
    test('Skeletonizer uses the brand lavender shimmer, not the package default', () {
      final config = AppTheme.lightTheme.extension<SkeletonizerConfigData>()!;
      final effect = config.effect as ShimmerEffect;
      expect(effect.colors.first, const Color(0xFFE7E5FA));
      expect(effect.colors.last, const Color(0xFFE7E5FA), reason: 'band returns to the base colour');
      expect(effect.colors, contains(const Color(0xFFF8F7FF)));
      expect(effect.duration, const Duration(milliseconds: 1600));
      expect(effect, isNot(const ShimmerEffect()), reason: 'not the default grey');
    });
  });

  group('Aurora skeleton card', () {
    Future<void> pumpGrid(WidgetTester tester, {double width = 360, double scale = 1}) async {
      tester.view.physicalSize = Size(width * 2, 1100 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await registerFakes(loggedIn: true, locale: 'ar');
      await tester.pumpWidget(
        auditApp(
          locale: 'ar',
          scale: scale,
          boundaryKey: GlobalKey(),
          child: const CustomScrollView(
            slivers: [AppSliverGridSkeleton(padding: EdgeInsets.all(16), aurora: true, itemCount: 4)],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('no solid brand-purple block: the cover shimmers (Bone) under a translucent white panel', (
      tester,
    ) async {
      await pumpGrid(tester);
      final solidPurple = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.primary,
      );
      expect(solidPurple, findsNothing);

      final panels = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            ((w.decoration as BoxDecoration).color?.a ?? 1) > 0.5 &&
            (w.decoration as BoxDecoration).color == Colors.white.withValues(alpha: 0.62),
      );
      expect(panels, findsNWidgets(4), reason: 'one glass-like panel per card');
      // غلاف + أربعة أسطر (تصنيف، عنوان ×2، بيانات) لكل بطاقة.
      expect(find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Bone')), findsAtLeastNWidgets(4 * 5));
    });

    for (final width in [320.0, 360.0, 411.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('fits at ${width.toInt()} dp, text scale $scale', (tester) async {
          await pumpGrid(tester, width: width, scale: scale);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets("the panel has the real panel's height", (tester) async {
      await pumpGrid(tester);
      final panel = find
          .byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == Colors.white.withValues(alpha: 0.62),
          )
          .first;
      expect(tester.getSize(panel).height, greaterThan(60));
    });
  });

  group('network image placeholder', () {
    setUp(() {
      // CachedNetworkImage يطلب مجلد الكاش قبل التنزيل.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
    });

    testWidgets('a soft lavender box shows until the picture arrives, and it fades out quickly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(width: 120, height: 80, child: AppNetworkImage(url: 'https://example.invalid/a.jpg')),
        ),
      );
      await tester.pump();
      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.placeholder, isNotNull);
      expect(image.fadeOutDuration, const Duration(milliseconds: 200), reason: 'default is a full second');
      final placeholder = image.placeholder!(tester.element(find.byType(CachedNetworkImage)), 'x');
      expect((placeholder as ColoredBox).color, AppColors.surfaceVariant);
    });

    testWidgets('a custom placeholder replaces the default', (tester) async {
      const custom = SizedBox(key: ValueKey('custom-wait'));
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 120,
            height: 80,
            child: AppNetworkImage(url: 'https://example.invalid/a.jpg', placeholder: custom),
          ),
        ),
      );
      await tester.pump();
      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.placeholder!(tester.element(find.byType(CachedNetworkImage)), 'x'), same(custom));
    });
  });
}
