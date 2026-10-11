/// مسارات Laravel API (مطابقة لـ routes/api.php).
abstract final class ApiEndpoints {
  static const studentLogin = '/student/login';
  static const studentRegister = '/student/register';
  static const studentLogout = '/student/logout';
  static const studentMe = '/student/me';
  static const studentProfile = '/student/profile';
  static const studentAccount = '/student/account';
  static const studentPasswordForgot = '/student/password/forgot';
  static const studentPasswordReset = '/student/password/reset';
  static const appConfig = '/app/config';
  static const studentSuggestedCourses = '/student/suggested-courses';
  static const studentEnrollments = '/student/enrollments';
  static String studentCancelEnrollment(int enrollmentId) => '/student/enrollments/$enrollmentId/cancel';
  static String studentEnrollmentPayment(int enrollmentId) => '/student/enrollments/$enrollmentId/payment';
  static String studentEnrollmentShamCash(int enrollmentId) => '/student/enrollments/$enrollmentId/payment/shamcash';
  static String courseFavorite(int courseId) => '/courses/$courseId/favorite';
  static String studentCourseFavorite(int courseId) => '/student/courses/$courseId/favorite';
  static String studentCourseReviews(int courseId) => '/student/courses/$courseId/reviews';
  static String courseReviews(int courseId) => '/courses/$courseId/reviews';
  static String instructorReviews(int instructorId) => '/instructors/$instructorId/reviews';
  static String instituteReviews(int instituteId) => '/institutes/$instituteId/reviews';
  static const studentNotifications = '/student/notifications';
  static const studentMobileVerificationSend = '/student/mobile-verification/send';
  static const studentMobileVerificationVerify = '/student/mobile-verification/verify';
  static const studentEmailVerificationSend = '/student/email-verification/send';
  static const studentEmailVerificationVerify = '/student/email-verification/verify';
  static const studentDevices = '/student/devices';
  static const logout = '/logout';

  static const homepage = '/homepage';
  static const search = '/search';

  static const users = '/users';
  static const cities = '/cities';
  static const categories = '/categories';
  static const tags = '/tags';
  static const universities = '/universities';
  static const specializations = '/specializations';
  static const institutes = '/institutes';
  static const instructors = '/instructors';
  static const courses = '/courses';
  static const courseSchedules = '/course-schedules';
  static const studentProfiles = '/student-profiles';
  static const reviews = '/reviews';
  static const studentReviews = '/student/reviews';
  static const favorites = '/favorites';
  static const studentFavorites = '/student/favorites';
  static const notifications = '/notifications';
  static const roles = '/roles';
  static const permissions = '/permissions';

  static String enrollByCourse(int courseId) => '/courses/$courseId/enroll';
  static String categoryById(int id) => '/categories/$id';
  static String categoryCourses(int id) => '/categories/$id/courses';
  static String cityById(int id) => '/cities/$id';
  static String cityInstitutes(int id) => '/cities/$id/institutes';
  static String courseById(int id) => '/courses/$id';
  static String instituteById(int id) => '/institutes/$id';
  static String instituteCourses(int id) => '/institutes/$id/courses';
  static String instructorById(int id) => '/instructors/$id';
  static String instructorCourses(int id) => '/instructors/$id/courses';
  static String resourceById(String path, int id) => '$path/$id';
}
