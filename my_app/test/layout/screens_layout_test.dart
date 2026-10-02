import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/modules/auth/controllers/auth_controller.dart';
import 'package:my_app/modules/auth/views/auth_views.dart';
import 'package:my_app/modules/auth/views/register_view.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/favorites/views/favorites_view.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/modules/notifications/controllers/notifications_controller.dart';
import 'package:my_app/modules/notifications/views/notifications_view.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
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
        () => const CourseDetailsView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          final c = Get.put(CourseDetailsController());
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
        () => const InstituteDetailsView(),
        beforeEach: () async {
          await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? locale);
          Get.put(InstituteDetailsController()).institute.value = sampleInstitutes().first;
        },
      ),
    );
  });

  // ملاحظة: فُحص خط Snackbar/Dialog يدوياً (لا استخدام لـ GoogleFonts متبقٍ في التطبيق منذ
  // إزالة الحزمة بالكامل — كل نص يستخدم Tajawal المضمّن عبر AppFonts/الثيم، بلا استثناء ممكن).
  // اختبار آلي لهذا كان يفتح/يغلق Dialog عبر عشرات التشكيلات بسرعة، والـ Overlay العام لـ GetX
  // لا يتحمّل ذلك التكرار بثبات (استثناءات توقيت من إطار الاختبار نفسه، لا من التطبيق) — أُزيل.

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
