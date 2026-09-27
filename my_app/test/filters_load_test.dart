import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/data/repositories/city_repository.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/data/repositories/institute_repository.dart';
import 'package:my_app/core/locale/locale_request_guard.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';

final _client = ApiClient(TokenStorage());

PaginatedResult<T> _emptyPage<T>() =>
    PaginatedResult<T>(items: [], currentPage: 1, lastPage: 1, total: 0, hasMore: false);

class _FakeCategoryRepository extends CategoryRepository {
  _FakeCategoryRepository() : super(_client);

  @override
  Future<List<CategoryModel>> fetchCategories({int perPage = 50}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return [
      CategoryModel.fromJson({'id': 1, 'name': 'Languages'}),
    ];
  }
}

class _FakeCourseRepository extends CourseRepository {
  _FakeCourseRepository() : super(_client, CourseRatingService(_client));

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _emptyPage();
  }
}

class _FakeCityRepository extends CityRepository {
  _FakeCityRepository() : super(_client);

  @override
  Future<List<CityModel>> fetchCities({int perPage = 100}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return [
      CityModel.fromJson({'id': 1, 'name': 'Damascus'}),
    ];
  }
}

class _FakeInstituteRepository extends InstituteRepository {
  _FakeInstituteRepository() : super(_client);

  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _emptyPage();
  }
}

void main() {
  setUp(() {
    Get.reset();
    Get.put(LocaleRequestGuard());
  });

  test('courses tab loads category filters on first open', () async {
    Get.put<CategoryRepository>(_FakeCategoryRepository());
    Get.put<CourseRepository>(_FakeCourseRepository());
    final controller = Get.put(CoursesController());

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(controller.categories, hasLength(1));
    expect(controller.isLoading.value, isFalse);
  });

  test('institutes tab loads city filters on first open', () async {
    Get.put<CityRepository>(_FakeCityRepository());
    Get.put<InstituteRepository>(_FakeInstituteRepository());
    final controller = Get.put(InstitutesController());

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(controller.cities, hasLength(1));
    expect(controller.isLoading.value, isFalse);
  });
}
