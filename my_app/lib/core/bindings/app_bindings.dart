import 'package:get/get.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../services/favorites_service.dart';
import '../services/student_id_resolver.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/city_repository.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/enrollment_repository.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/instructor_repository.dart';
import '../data/repositories/institute_repository.dart';
import '../storage/favorites_storage.dart';
import '../storage/recent_search_storage.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/reference_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/search_repository.dart';
import '../services/course_rating_service.dart';
import '../network/api_client.dart';
import '../locale/locale_controller.dart';
import '../storage/token_storage.dart';

/// حقن التبعيات مرة واحدة — بدون تكرار.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TokenStorage>()) {
      Get.put(TokenStorage(), permanent: true);
    }
    if (!Get.isRegistered<LocaleController>()) {
      Get.put(LocaleController(), permanent: true);
    }
    if (!Get.isRegistered<FavoritesStorage>()) {
      Get.put(FavoritesStorage(), permanent: true);
    }
    if (!Get.isRegistered<RecentSearchStorage>()) {
      Get.put(RecentSearchStorage(), permanent: true);
    }
    if (!Get.isRegistered<ApiClient>()) {
      Get.put(ApiClient(Get.find<TokenStorage>()), permanent: true);
    }

    Get.lazyPut(() => AuthRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => CourseRatingService(Get.find()), fenix: true);
    Get.lazyPut(() => CourseRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => InstituteRepository(Get.find()), fenix: true);
    Get.lazyPut(() => CategoryRepository(Get.find()), fenix: true);
    Get.lazyPut(() => HomeRepository(Get.find()), fenix: true);
    Get.lazyPut(() => NotificationRepository(Get.find()), fenix: true);
    Get.lazyPut(() => ProfileRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => ReferenceRepository(Get.find()), fenix: true);
    Get.lazyPut(() => StudentIdResolver(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => SearchRepository(Get.find(), Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => CityRepository(Get.find()), fenix: true);
    Get.lazyPut(() => ReviewRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => EnrollmentRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => InstructorRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => FavoritesRepository(Get.find(), Get.find()), fenix: true);
    if (!Get.isRegistered<FavoritesService>()) {
      Get.put(FavoritesService(Get.find(), Get.find()), permanent: true);
    }
  }
}
