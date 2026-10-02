import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/theme/app_theme.dart';

/// مجلد اختياري لحفظ لقطات الشاشة: flutter test --dart-define=LAYOUT_DUMP_DIR=C:/path
const layoutDumpDir = String.fromEnvironment('LAYOUT_DUMP_DIR');

class AuditViewport {
  const AuditViewport(this.name, this.size);
  final String name;
  final Size size;
}

const auditViewports = [
  AuditViewport('phone-320', Size(320, 640)),
  AuditViewport('phone-360', Size(360, 780)),
  AuditViewport('phone-390', Size(390, 844)),
  AuditViewport('phone-430', Size(430, 932)),
  AuditViewport('tablet-768', Size(768, 1024)),
  AuditViewport('tablet-1024', Size(1024, 1366)),
  AuditViewport('landscape-844', Size(844, 390)),
];

/// 1.0 = افتراضي، 1.3 = أقصى تكبير يسمح به التطبيق (app.dart).
const auditScales = [1.0, 1.3];
const auditLocales = ['ar', 'en'];

/// لقطات تُحفظ فقط لهذه التركيبات (لتقليل عدد الصور) — كل المشاكل تُرصد في كل التركيبات.
bool shouldDump(AuditViewport v, double scale, String locale) =>
    layoutDumpDir.isNotEmpty &&
    ((v.name == 'phone-360' && locale == 'ar') ||
        (v.name == 'phone-320' && scale > 1 && locale == 'ar') ||
        (v.name == 'tablet-768' && scale == 1 && locale == 'ar') ||
        (v.name == 'phone-390' && scale == 1 && locale == 'en') ||
        (v.name == 'landscape-844' && scale == 1 && locale == 'ar'));

Future<void> loadAuditFonts() async {
  final tajawal = FontLoader('Tajawal');
  for (final w in ['Regular', 'Medium', 'Bold', 'ExtraBold', 'Black']) {
    tajawal.addFont(rootBundle.load('assets/fonts/tajawal/Tajawal-$w.ttf'));
  }
  await tajawal.load();
  try {
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  } catch (_) {
    // الأيقونات تظهر مربعات في اللقطات فقط — لا يؤثر على فحص التخطيط.
  }
}

class LayoutIssue {
  LayoutIssue(this.scene, this.config, this.kind, this.detail);
  final String scene;
  final String config;
  final String kind;
  final String detail;

  /// مفتاح لتجميع نفس المشكلة عبر عدة مقاسات.
  String get key => '$scene|$kind|$detail';
}

Widget auditApp({required Widget child, required String locale, required double scale, required Key boundaryKey}) {
  return RepaintBoundary(
    key: boundaryKey,
    child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: Locale(locale),
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, c) => Directionality(
        textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(backgroundColor: AppColors.surface, body: child),
    ),
  );
}

String _short(RenderParagraph node) {
  final text = node.text.toPlainText().replaceAll('\n', ' ').trim();
  return text.length > 40 ? '${text.substring(0, 40)}…' : text;
}

/// أول عائلة خط فعلية في النص (مع الوراثة من DefaultTextStyle — Text يدمجها في الـ span).
/// الخط الفعلي لكل جزء نصّي، مع وراثة الخط من الأب كما يفعل محرّك النص.
/// (لا نستخدم visitChildren لأنه يتجاهل الـ spans بلا نص، ومنها الجذر الذي يحمل خط DefaultTextStyle.)
void _leafFamilies(InlineSpan span, String? inherited, List<String?> out) {
  final family = span.style?.fontFamily ?? inherited;
  if (span is! TextSpan) return;
  if ((span.text ?? '').trim().isNotEmpty) out.add(family);
  for (final child in span.children ?? const <InlineSpan>[]) {
    _leafFamilies(child, family, out);
  }
}

/// يفحص كل النصوص المرسومة:
/// - squeezed-text: أُعطي النص مساحة أقل مما يحتاج (يتداخل مع ما تحته) — لا يظهر كخطأ Flutter.
/// - font-fallback: نص لا يستخدم Tajawal (يظهر بخط النظام على الجهاز).
/// - truncated: نص قُصّ بـ "…".
List<(String kind, String detail)> inspectText(WidgetTester tester) {
  final found = <(String, String)>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph && node.hasSize && node.size.width > 0) {
      final label = _short(node);
      final needed = node.getDryLayout(BoxConstraints(maxWidth: node.size.width)).height;
      if (needed - node.size.height > 1.5) {
        found.add((
          'squeezed-text',
          '"$label" needs ${needed.toStringAsFixed(0)}px, gets ${node.size.height.toStringAsFixed(0)}px',
        ));
      }
      final families = <String?>[];
      _leafFamilies(node.text, null, families);
      final isIcon = families.any((f) => f == 'MaterialIcons' || f == 'CupertinoIcons');
      final wrong = families.where((f) => f != 'Tajawal').toSet();
      if (!isIcon && label.isNotEmpty && wrong.isNotEmpty) {
        found.add(('font-fallback', '"$label" uses font ${wrong.map((f) => f ?? '(system default)').join(', ')}'));
      }
      if (!isIcon && node.didExceedMaxLines) {
        found.add(('truncated', '"$label"'));
      }
    }
    node.visitChildren(visit);
  }

  for (final view in tester.binding.renderViews) {
    visit(view);
  }
  return found;
}

String _describeError(FlutterErrorDetails details) {
  final text = details.toString();
  final first = details.exceptionAsString().split('\n').first;
  final location = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text)?.group(0) ?? '';
  return location.isEmpty ? first : '$first @ $location';
}

/// يرسم [scene] بكل التركيبات ويجمع المشاكل.
Future<List<LayoutIssue>> auditScene(
  WidgetTester tester,
  String sceneName,
  Widget Function() scene, {
  Future<void> Function()? beforeEach,
  Duration settle = const Duration(milliseconds: 600),
  List<AuditViewport>? viewports,
  List<double>? scales,
  List<String>? locales,
}) async {
  final issues = <LayoutIssue>[];
  for (final viewport in viewports ?? auditViewports) {
    for (final scale in scales ?? auditScales) {
      for (final locale in locales ?? auditLocales) {
        final config = '${viewport.name} x$scale $locale';
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        Get.locale = Locale(locale);
        if (beforeEach != null) await beforeEach();

        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) => errors.add(_describeError(details));
        final key = GlobalKey();
        try {
          await tester.pumpWidget(auditApp(child: scene(), locale: locale, scale: scale, boundaryKey: key));
          await tester.pump(settle);
          await tester.pump(settle);
        } finally {
          FlutterError.onError = previous;
        }
        final pending = tester.takeException();
        if (pending != null) errors.add(pending.toString().split('\n').first);

        for (final e in errors) {
          issues.add(LayoutIssue(sceneName, config, e.contains('overflowed') ? 'overflow' : 'exception', e));
        }
        for (final (kind, detail) in inspectText(tester)) {
          // القصّ بـ "…" مقصود في أماكن كثيرة — نرصده فقط على مقاس الهاتف الشائع وبالخط الافتراضي.
          if (kind == 'truncated' && !(viewport.name == 'phone-360' && scale == 1.0)) continue;
          issues.add(LayoutIssue(sceneName, config, kind, detail));
        }

        if (shouldDump(viewport, scale, locale)) {
          await _dump(tester, key, '${sceneName}__${viewport.name}_x${scale}_$locale.png');
        }
        // إغلاق أي Snackbar/Dialog قبل تبديل الشجرة — وإلا يبقى مؤقّت الأنيميشن حياً بعد التخلص من
        // الـ Overlay فيرمي استثناءً عشوائي التوقيت لا علاقة له بتخطيط التطبيق نفسه.
        Get.closeAllSnackbars();
        if (Get.isDialogOpen ?? false) Get.back();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  }
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  return issues;
}

Future<void> _dump(WidgetTester tester, GlobalKey key, String fileName) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = Directory(layoutDumpDir)..createSync(recursive: true);
    File('${dir.path}/$fileName').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

/// تقرير مختصر: كل مشكلة مرة واحدة مع قائمة المقاسات التي ظهرت فيها.
String formatIssues(List<LayoutIssue> issues) {
  final grouped = <String, List<LayoutIssue>>{};
  for (final i in issues) {
    grouped.putIfAbsent(i.key, () => []).add(i);
  }
  final buffer = StringBuffer();
  for (final entry in grouped.entries) {
    final first = entry.value.first;
    final configs = entry.value.map((i) => i.config).toSet();
    buffer.writeln('[${first.scene}] ${first.kind}: ${first.detail}');
    buffer.writeln('    in ${configs.length} configs: ${configs.take(6).join(', ')}${configs.length > 6 ? ', …' : ''}');
  }
  return buffer.toString();
}
