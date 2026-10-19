import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/navigation/app_page_transition.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';
import 'package:my_app/theme/app_motion.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// الهيكل يطابق البطاقة الحقيقية: الصفحة تُفتح والطلبات معلّقة (هيكل)، ثم يصل الرد — أول بطاقة حقيقية
/// يجب أن تأخذ مكان أول بطاقة هيكل وارتفاعها نفسه (لا قفزة)، والهيكل نفسه بلا overflow، والصفحة تنتهي
/// ببيانات لا بهيكل.
class _Case {
  const _Case(this.route, this.arguments, this.realItem, {this.matchSize = true, this.tab, this.tolerance = 1});

  final String route;
  final Object? Function() arguments;

  /// اسم نوع البطاقة الحقيقية الأولى في القائمة.
  final String realItem;

  /// false: عناصر بارتفاع متغيّر (نص بلا حدّ أسطر) — نتحقق من الموضع وانتهاء التحميل ببيانات، لا الارتفاع.
  final bool matchSize;

  /// مفتاح ترجمة تبويب يُفتح أثناء التحميل (تبويبات صفحات التفاصيل).
  final String? tab;

  /// فرق مسموح بالبكسل.
  final double tolerance;
}

final _cases = <_Case>[
  _Case(AppRoutes.cityDetails, () => {'id': 1, 'name': 'دمشق'}, 'InstituteListCard'),
  _Case(AppRoutes.privateInstructors, () => null, 'PrivateInstructorListCard'),
  _Case(
    AppRoutes.instructorSubjectInstructors,
    () => {'key': 'spec:1', 'name': 'رياضيات'},
    'PrivateInstructorListCard',
  ),
  _Case(AppRoutes.categoryCourses, () => {'id': 3, 'name': 'البرمجة'}, 'CourseAuroraCard'),
  _Case(AppRoutes.instructorCourses, () => sampleInstructors().first, 'CourseCard'),
  _Case(AppRoutes.favorites, () => null, 'CourseAuroraCard'),
  _Case(AppRoutes.notifications, () => null, 'NotificationCard', matchSize: false),
  _Case(
    AppRoutes.instituteDetails,
    () => sampleInstitutes().first,
    '_InstituteCourseTile',
    tab: 'tab_courses',
    matchSize: false,
  ),
  _Case(
    AppRoutes.instituteDetails,
    () => sampleInstitutes().first,
    'PrivateInstructorListCard',
    tab: 'tab_instructors',
  ),
  // شبكة التبويب الحقيقية بلا هامش +2 الموحّد لشبكة الدورات: فرق 2 px في ارتفاع الخلية.
  _Case(AppRoutes.instructorDetails, () => sampleInstructors().first, 'CourseCard', tab: 'tab_courses', tolerance: 2.5),
];

const _configs = [(360.0, 1.0, 'ar'), (320.0, 1.3, 'en'), (411.0, 1.0, 'en')];

Finder _byTypeName(String name) => find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

/// بطاقات الهياكل المرسومة يدوياً في app_skeletons.dart.
const _skeletonCards = {
  '_SkeletonRowCard',
  '_SkeletonListTile',
  '_SkeletonAuroraCard',
  '_SkeletonCourseCard',
  '_SkeletonPosterCard',
  '_SkeletonInstituteMiniCard',
};

final _activeSkeleton = find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled);

/// أول بطاقة داخل هيكل نشط: بطاقة هيكل مرسومة، أو البطاقة الحقيقية نفسها ببيانات وهمية.
Finder _skeletonItem(String realItem) => find.descendant(
  of: _activeSkeleton,
  matching: find.byWidgetPredicate((w) {
    final name = w.runtimeType.toString();
    return name == realItem || _skeletonCards.contains(name);
  }),
);

void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  for (final (width, scale, locale) in _configs) {
    for (final c in _cases) {
      final name = c.tab == null ? c.route : '${c.route} [${c.tab}]';
      testWidgets('$name @ ${width.toInt()}dp x$scale $locale: skeleton -> data without a jump', (tester) async {
        tester.view.physicalSize = Size(width * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final overflows = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) {
            overflows.add(text.split('\n').first);
          } else {
            original?.call(details);
          }
        };
        try {
          await registerFakes(loggedIn: true, locale: locale);
          await tester.pumpWidget(
            GetMaterialApp(
              translations: AppTranslations(),
              locale: Locale(locale),
              getPages: AppPages.pages,
              navigatorObservers: [RouteMotionObserver()],
              customTransition: AppPageTransition(),
              transitionDuration: AppMotion.fast,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const Scaffold(body: Text('home')),
            ),
          );
          await tester.pumpAndSettle();

          // كل الطلبات معلّقة حتى نطلقها: الصفحة على الهيكل.
          final gate = FakeApi.gate = Completer<void>();
          Get.toNamed<void>(c.route, arguments: c.arguments());
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          if (c.tab != null) {
            await tester.tap(find.text(c.tab!.tr).first);
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
          final skeleton = _skeletonItem(c.realItem);
          expect(skeleton, findsWidgets, reason: 'nothing to show yet -> skeleton');
          final skeletonRect = tester.getRect(skeleton.first);
          // overflow الهيكل نفسه (overflow المحتوى الحقيقي تغطيه اختبارات التخطيط).
          expect(overflows, isEmpty, reason: 'skeleton overflow: ${overflows.toSet()}');

          gate.complete();
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();

          expect(_activeSkeleton, findsNothing, reason: 'loading ended (no endless skeleton)');
          final real = _byTypeName(c.realItem);
          expect(real, findsWidgets, reason: 'loading ended in data');
          final realRect = tester.getRect(real.first);
          expect(
            (realRect.top - skeletonRect.top).abs(),
            lessThanOrEqualTo(c.tolerance),
            reason: 'first item jumps from y=${skeletonRect.top} to y=${realRect.top}',
          );
          if (c.matchSize) {
            expect(
              (realRect.height - skeletonRect.height).abs(),
              lessThanOrEqualTo(c.tolerance),
              reason: 'skeleton item ${skeletonRect.height} vs real ${realRect.height}',
            );
          }
        } finally {
          FlutterError.onError = original;
        }
      });
    }
  }
}
