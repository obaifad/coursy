import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/modules/auth/controllers/auth_controller.dart';
import 'package:my_app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:my_app/modules/auth/views/auth_views.dart';
import 'package:my_app/modules/auth/views/register_view.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/category_courses_view.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/favorites/views/favorites_view.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/modules/instructors/controllers/instructor_details_controller.dart';
import 'package:my_app/modules/instructors/views/instructor_details_view.dart';
import 'package:my_app/modules/instructors/controllers/private_instructors_controller.dart';
import 'package:my_app/modules/instructors/views/private_instructors_view.dart';
import 'package:my_app/modules/notifications/controllers/notifications_controller.dart';
import 'package:my_app/modules/notifications/views/notifications_view.dart';
import 'package:my_app/modules/payment/controllers/payment_controller.dart';
import 'package:my_app/modules/payment/views/payment_view.dart';
import 'package:my_app/modules/profile/controllers/delete_account_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/profile/views/delete_account_view.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/modules/search/controllers/search_controller.dart';
import 'package:my_app/modules/search/views/search_view.dart';

import 'fakes.dart';
import 'layout_harness.dart';
import 'sample_data.dart';

/// فحص تخطيط الشاشات الرئيسية (مع بطاقاتها الخاصة) بكل المقاسات — بيانات وهمية، بلا شبكة.
void main() {
  final allIssues = <LayoutIssue>[];
  var locale = 'ar';

  setUpAll(loadAuditFonts);

  tearDownAll(() {
    // ignore: avoid_print
    print('\n===== SCREENS LAYOUT REPORT (${allIssues.length} findings) =====\n${formatIssues(allIssues)}');
  });

  Future<void> rootSetup({required bool loggedIn, required int tab}) async {
    final tokens = await registerFakes(loggedIn: loggedIn, locale: Get.locale?.languageCode ?? locale);
    Get.put(HomeController(tokens));
    Get.put(CoursesController());
    Get.put(InstitutesController());
    Get.put(MyCoursesController());
    Get.put(RootController()).currentIndex.value = tab;
  }

  const tabNames = ['courses', 'institutes', 'home', 'my-courses', 'profile'];
  for (var tab = 0; tab < tabNames.length; tab++) {
    for (final loggedIn in [true, false]) {
      // تبويبا دوراتي والملف الشخصي فقط يختلفان للضيف.
      if (!loggedIn && tab < 3) continue;
      final name = 'tab-${tabNames[tab]}${loggedIn ? '' : '-guest'}';
      testWidgets(name, (tester) async {
        allIssues.addAll(
          await auditScene(
            tester,
            name,
            () => const RootView(),
            beforeEach: () => rootSetup(loggedIn: loggedIn, tab: tab),
          ),
        );
      });
    }
  }

  testWidgets('favorites', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'favorites',
        () => const FavoritesView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(FavoritesController());
        },
      ),
    );
  });

  // شاشات القوائم بنمط «الرأس يختفي والفلاتر تلتصق» — لم تكن في الفحص.
  testWidgets('category courses', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'category-courses',
        () => const CategoryCoursesView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.routing.args = <String, dynamic>{'id': 3, 'name': 'البرمجة وتطوير التطبيقات'};
          Get.put(CategoryCoursesController());
        },
      ),
    );
  });

  testWidgets('private instructors', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'private-instructors',
        () => const PrivateInstructorsView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.routing.args = null;
          Get.put(PrivateInstructorsController(Get.find()));
        },
      ),
    );
  });

  testWidgets('search results', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'search-results',
        () => const SearchView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(SearchPageController()).queryController.text = 'فلاتر';
        },
      ),
    );
  });

  testWidgets('search recent', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'search-recent',
        () => const SearchView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(SearchPageController());
        },
      ),
    );
  });

  testWidgets('notifications', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'notifications',
        () => const NotificationsView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(NotificationsController());
        },
      ),
    );
  });

  testWidgets('course details', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'course-details',
        () => const CourseDetailsView(controllerTag: 'course-test'),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          final c = Get.put(CourseDetailsController(), tag: 'course-test');
          c.course.value = sampleCourses().first;
          c.schedules.assignAll(sampleSchedules());
          c.reviews.assignAll(sampleReviews());
        },
      ),
    );
  });

  testWidgets('institute details', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'institute-details',
        () => const InstituteDetailsView(controllerTag: 'institute-test'),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(InstituteDetailsController(), tag: 'institute-test').institute.value = sampleInstitutes().first;
        },
      ),
    );
  });

  testWidgets('instructor details', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'instructor-details',
        () => const InstructorDetailsView(controllerTag: 'instructor-test'),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(InstructorDetailsController(), tag: 'instructor-test').instructor.value = sampleInstructors().first;
        },
      ),
    );
  });

  // ملاحظة: فُحص خط Snackbar/Dialog يدوياً (لا استخدام لـ GoogleFonts متبقٍ في التطبيق منذ
  // إزالة الحزمة بالكامل — كل نص يستخدم Tajawal المضمّن عبر AppFonts/الثيم، بلا استثناء ممكن).
  // اختبار آلي لهذا كان يفتح/يغلق Dialog عبر عشرات التشكيلات بسرعة، والـ Overlay العام لـ GetX
  // لا يتحمّل ذلك التكرار بثبات (استثناءات توقيت من إطار الاختبار نفسه، لا من التطبيق) — أُزيل.

  const shamcash = {
    'available': true,
    'account_name': 'معهد مسار للتدريب والتطوير المهني',
    'address': 'SC-ADDRESS-123456789ABCDEF',
    'qr_payload': 'shamcash://pay/SC-ADDRESS-123456789ABCDEF',
  };
  const base = {
    'enrollment_id': 42,
    'payment_status': 'unpaid',
    'currency': 'SYP',
    'amount_due': 1250000,
    'advance_amount': 300000,
    'amount_paid': 0,
    'amount_remaining': 1250000,
    'advance_remaining': 300000,
    'shamcash': shamcash,
    'payments': [],
  };
  final paymentScenes = <String, Map<String, dynamic>>{
    'payment-unpaid': base,
    'payment-partial': {
      ...base,
      'payment_status': 'partial',
      'amount_paid': 300000,
      'amount_remaining': 950000,
      'advance_remaining': 0,
      'payments': [
        {
          'id': 7,
          'transaction_id': '555123456789',
          'amount': '300000.00',
          'currency': 'SYP',
          'occurred_at': '2026-10-03T06:15:00.000000Z',
        },
      ],
    },
    'payment-paid': {
      ...base,
      'payment_status': 'paid',
      'amount_paid': 1250000,
      'amount_remaining': 0,
      'advance_remaining': 0,
    },
    'payment-unavailable': {
      ...base,
      'shamcash': {'available': false},
    },
  };
  for (final scene in paymentScenes.entries) {
    testWidgets(scene.key, (tester) async {
      allIssues.addAll(
        await auditScene(
          tester,
          scene.key,
          () => const PaymentView(),
          beforeEach: () async {
            await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
            fakePaymentJson = scene.value;
            Get.put(PaymentController(enrollmentId: 42));
          },
        ),
      );
    });
  }

  testWidgets('delete account', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'delete-account',
        () => const DeleteAccountView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(DeleteAccountController()).passwordError.value = 'كلمة المرور غير صحيحة.';
        },
      ),
    );
  });

  for (final codeStep in [false, true]) {
    final name = codeStep ? 'forgot-password-code' : 'forgot-password-email';
    testWidgets(name, (tester) async {
      allIssues.addAll(
        await auditScene(
          tester,
          name,
          () => const ForgotPasswordView(),
          beforeEach: () async {
            await registerFakes(loggedIn: false, locale: Get.locale?.languageCode ?? locale);
            final c = Get.put(ForgotPasswordController());
            c.emailController.text = 'student.with.a.long.address@coursy.sy';
            if (codeStep) {
              c.step.value = 1;
              c.resendIn.value = 45;
            }
          },
        ),
      );
    });
  }

  testWidgets('login', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'login',
        () => const LoginView(),
        beforeEach: () async {
          await registerFakes(loggedIn: false, locale: Get.locale?.languageCode ?? locale);
          Get.put(AuthController());
        },
      ),
    );
  });

  testWidgets('register', (tester) async {
    allIssues.addAll(
      await auditScene(
        tester,
        'register',
        () => const RegisterView(),
        beforeEach: () async {
          await registerFakes(loggedIn: false, locale: Get.locale?.languageCode ?? locale);
          Get.put(AuthController());
        },
      ),
    );
  });
}
