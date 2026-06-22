import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/auth/controllers/phone_verification_controller.dart';
import '../modules/auth/views/auth_views.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/auth/views/phone_verification_view.dart';
import '../modules/courses/controllers/course_details_controller.dart';
import '../modules/courses/controllers/booking_controller.dart';
import '../modules/courses/controllers/category_courses_controller.dart';
import '../modules/courses/controllers/instructor_courses_controller.dart';
import '../modules/instructors/controllers/instructor_details_controller.dart';
import '../modules/instructors/controllers/instructor_subject_instructors_controller.dart';
import '../modules/instructors/controllers/private_instructors_controller.dart';
import '../modules/instructors/views/instructor_details_view.dart';
import '../modules/instructors/views/instructor_subject_instructors_view.dart';
import '../modules/instructors/views/private_instructors_view.dart';
import '../modules/courses/views/booking_view.dart';
import '../modules/courses/views/category_courses_view.dart';
import '../modules/courses/views/instructor_courses_view.dart';
import '../modules/courses/views/course_details_view.dart';
import '../modules/institutes/controllers/city_details_controller.dart';
import '../modules/institutes/views/city_details_view.dart';
import '../modules/profile/controllers/my_courses_controller.dart';
import '../modules/institutes/controllers/institutes_controller.dart';
import '../modules/institutes/views/institutes_views.dart';
import '../modules/notifications/controllers/notifications_controller.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/profile/views/profile_views.dart';
import '../core/bindings/root_binding.dart';
import '../modules/root/views/root_view.dart';
import '../modules/search/controllers/search_controller.dart';
import '../modules/search/views/search_view.dart';
import '../modules/favorites/controllers/favorites_controller.dart';
import '../modules/favorites/views/favorites_view.dart';
import '../modules/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.lazyPut<AuthController>(() => AuthController());
        }
      }),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.lazyPut<AuthController>(() => AuthController());
        }
      }),
    ),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordView()),
    GetPage(
      name: AppRoutes.phoneVerification,
      page: () => const PhoneVerificationView(),
      binding: BindingsBuilder(() => Get.lazyPut<PhoneVerificationController>(() => PhoneVerificationController())),
    ),
    GetPage(
      name: AppRoutes.root,
      page: () => const RootView(),
      binding: RootBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
      binding: BindingsBuilder(() => Get.lazyPut<SearchPageController>(() => SearchPageController())),
    ),
    GetPage(
      name: AppRoutes.courseDetails,
      page: () => const CourseDetailsView(),
      binding: BindingsBuilder(() => Get.lazyPut<CourseDetailsController>(() => CourseDetailsController())),
    ),
    GetPage(
      name: AppRoutes.categoryCourses,
      page: () => const CategoryCoursesView(),
      binding: BindingsBuilder(() => Get.lazyPut<CategoryCoursesController>(() => CategoryCoursesController())),
    ),
    GetPage(
      name: AppRoutes.instructorCourses,
      page: () => const InstructorCoursesView(),
      binding: BindingsBuilder(() => Get.lazyPut<InstructorCoursesController>(() => InstructorCoursesController())),
    ),
    GetPage(
      name: AppRoutes.privateInstructors,
      page: () => const PrivateInstructorsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut<PrivateInstructorsController>(
          () => PrivateInstructorsController(Get.find()),
        ),
      ),
    ),
    GetPage(
      name: AppRoutes.instructorDetails,
      page: () => const InstructorDetailsView(),
      binding: BindingsBuilder(() => Get.lazyPut<InstructorDetailsController>(() => InstructorDetailsController())),
    ),
    GetPage(
      name: AppRoutes.instructorSubjectInstructors,
      page: () => const InstructorSubjectInstructorsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut<InstructorSubjectInstructorsController>(() => InstructorSubjectInstructorsController()),
      ),
    ),
    GetPage(
      name: AppRoutes.instituteDetails,
      page: () => const InstituteDetailsView(),
      binding: BindingsBuilder(() => Get.lazyPut<InstituteDetailsController>(() => InstituteDetailsController())),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: BindingsBuilder(() => Get.lazyPut<NotificationsController>(() => NotificationsController())),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: BindingsBuilder(() {
        ProfileController.ensureRegistered();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!Get.isRegistered<ProfileController>()) return;
          final controller = Get.find<ProfileController>();
          if (!controller.isLoading.value) {
            controller.captureEditBaseline();
          }
        });
      }),
    ),
    GetPage(
      name: AppRoutes.myCourses,
      page: () => const MyCoursesView(),
      binding: BindingsBuilder(() => Get.lazyPut<MyCoursesController>(() => MyCoursesController())),
    ),
    GetPage(
      name: AppRoutes.courseBooking,
      page: () => const CourseBookingView(),
      binding: BindingsBuilder(() => Get.lazyPut<BookingController>(() => BookingController())),
    ),
    GetPage(
      name: AppRoutes.cityDetails,
      page: () => const CityDetailsView(),
      binding: BindingsBuilder(() => Get.lazyPut<CityDetailsController>(() => CityDetailsController())),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView()),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<FavoritesController>()) {
          Get.lazyPut<FavoritesController>(() => FavoritesController());
        }
      }),
    ),
  ];
}
