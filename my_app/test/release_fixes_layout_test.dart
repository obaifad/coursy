import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/enrollment_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/modules/auth/controllers/auth_controller.dart';
import 'package:my_app/modules/auth/views/auth_views.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/profile/views/my_courses_tab_view.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/theme/app_system_ui.dart';
import 'package:my_app/theme/app_theme.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// هاتف 1080×2400 (‏2.625 بكسل لكل نقطة) — حيث ظهر القصّ في التقرير.
const _phone = Size(1080 / 2.625, 2400 / 2.625);

class _Enrollments extends EnrollmentRepository {
  _Enrollments(super.client, this.items);
  final List<EnrollmentModel> items;

  @override
  Future<PaginatedResult<EnrollmentModel>> fetchEnrollmentsPage({int page = 1, int perPage = 15}) async =>
      PaginatedResult(items: items, currentPage: 1, lastPage: 1, total: items.length, hasMore: false);

  @override
  Future<List<EnrollmentModel>> fetchEnrollments() async => items;
}

EnrollmentModel _pendingWithAdvance({required String studyType}) => EnrollmentModel.fromJson({
  'id': 11,
  'status': 'pending',
  'payment_status': 'unpaid',
  'course': {
    'id': 1,
    'title': longCourseAr,
    'title_ar': longCourseAr,
    'title_en': longCourseEn,
    'price': '1500000',
    'study_type': studyType,
    'requires_advance_payment': true,
    'institute': {'id': 2, 'name_ar': 'أكاديمية المهارات', 'name_en': 'Skills Academy', 'accepts_shamcash': true},
  },
});

Future<void> _useEnrollments(List<EnrollmentModel> items) async {
  Get.delete<EnrollmentRepository>(force: true);
  Get.put<EnrollmentRepository>(_Enrollments(Get.find(), items));
  fakePaymentJson = {
    'enrollment_id': 11,
    'payment_status': 'unpaid',
    'currency': 'SYP',
    'amount_due': 1250000,
    'advance_amount': 300000,
    'amount_paid': 0,
    'amount_remaining': 1250000,
    'advance_remaining': 300000,
    'shamcash': {'available': true, 'account_name': 'Skills Academy', 'address': 'SC-1'},
    'payments': [],
  };
}

Future<void> _pumpScene(
  WidgetTester tester,
  Widget scene, {
  required String locale,
  double scale = 1,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(auditApp(child: scene, locale: locale, scale: scale, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _disposeScene(WidgetTester tester) async {
  Get.closeAllSnackbars();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

List<String> _truncatedTexts(WidgetTester tester) => [
  for (final (kind, detail) in inspectText(tester))
    if (kind == 'truncated') detail,
];

void main() {
  setUpAll(loadAuditFonts);

  for (final locale in ['ar', 'en']) {
    for (final (name, size, scale) in [
      ('1080px phone', _phone, 1.0),
      ('1080px phone', _phone, 1.3),
      ('360dp phone', const Size(360, 780), 1.0),
    ]) {
      testWidgets('login identifier label and hint fit on a $name ($locale x$scale)', (tester) async {
        Get.locale = Locale(locale);
        await registerFakes(loggedIn: false, locale: locale);
        Get.put(AuthController());
        await _pumpScene(tester, const LoginView(), locale: locale, scale: scale, size: size);

        final label = 'login_identifier_short'.tr;
        expect(find.text(label), findsOneWidget);
        final truncated = _truncatedTexts(tester);
        expect(truncated, isNot(contains('"$label"')));
        // المثال (يظهر عند التركيز) يتسع أيضاً على هاتف التقرير بحجم الخط الافتراضي.
        if (size == _phone && scale == 1.0) expect(truncated, isEmpty);
        await _disposeScene(tester);
      });
    }

    testWidgets('booking card shows full "view details" next to "pay now" ($locale)', (tester) async {
      Get.locale = Locale(locale);
      await registerFakes(loggedIn: true, locale: locale);
      await _useEnrollments([_pendingWithAdvance(studyType: 'offline')]);
      Get.put(MyCoursesController());
      await _pumpScene(tester, const MyCoursesTabView(), locale: locale);

      final details = find.text('view_details'.tr);
      expect(find.text('payment_pay_now'.tr), findsOneWidget);
      expect(details, findsOneWidget);
      // يُرسم بحجمه الطبيعي: لا قصّ ولا تصغير.
      final fitted = find.ancestor(of: details, matching: find.byType(FittedBox));
      expect(tester.getSize(fitted).width, greaterThanOrEqualTo(tester.getSize(details).width - 0.5));
      expect(_truncatedTexts(tester), isNot(contains(contains('view_details'.tr))));
      await _disposeScene(tester);
    });
  }

  testWidgets('online courses show only "view details"', (tester) async {
    Get.locale = const Locale('ar');
    await registerFakes(loggedIn: true, locale: 'ar');
    await _useEnrollments([_pendingWithAdvance(studyType: 'online')]);
    Get.put(MyCoursesController());
    await _pumpScene(tester, const MyCoursesTabView(), locale: 'ar');

    expect(find.text('payment_pay_now'.tr), findsNothing);
    expect(find.text('view_details'.tr), findsOneWidget);
    await _disposeScene(tester);
  });

  group('status bar icons', () {
    Future<void> pumpRoot(WidgetTester tester, {required int tab}) async {
      Get.locale = const Locale('ar');
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(HomeController(tokens));
      Get.put(CoursesController());
      Get.put(InstitutesController());
      Get.put(MyCoursesController());
      Get.put(RootController()).currentIndex.value = tab;
      await _pumpScene(tester, const RootView(), locale: 'ar');
    }

    testWidgets('profile tab (purple header) gets light icons, the other tabs dark ones', (tester) async {
      await pumpRoot(tester, tab: 4);
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);

      Get.find<RootController>().changeTab(2);
      await tester.pump(const Duration(milliseconds: 600));
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
      await _disposeScene(tester);
    });

    testWidgets('a transparent AppBar on a light screen gets dark icons', (tester) async {
      // كما بعد زيارة الملف الشخصي: آخر نمط مطبّق أيقونات فاتحة.
      SystemChrome.setSystemUIOverlayStyle(AppSystemUi.lightIcons);
      await tester.pump();
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Edit profile')),
          ),
        ),
      );
      await tester.pump();
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
    });
  });
}
