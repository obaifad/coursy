import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';

class HomeRepository extends GetxService {
  HomeRepository(this._client);

  final ApiClient _client;

  /// يحاول جلب الصفحة الرئيسية؛ إن فشل أو كانت فارغة يُرجع null ليُكمّل الـ Controller بجلب منفصل.
  Future<HomePayload?> fetchHomepage() async {
    try {
      return await _client.handle(
        () => _client.get(ApiEndpoints.homepage),
        (data) {
          if (data is! Map<String, dynamic>) {
            return null;
          }
          final map = extractObjectMap(data) ?? data;
          return HomePayload(
            courses: extractListMap(map['featured_courses'] ?? map['courses']).map(CourseModel.fromJson).toList(),
            // للزوار فقط — المسجّلون يستخدمون /student/suggested-courses
            suggestedCourses: extractListMap(map['latest_courses'] ?? map['suggested_courses'])
                .map(CourseModel.fromJson)
                .toList(),
            institutes: extractListMap(map['institutes'] ?? map['top_institutes']).map(InstituteModel.fromJson).toList(),
            categories: extractListMap(map['categories']).map(CategoryModel.fromJson).toList(),
            cities: extractListMap(map['cities']).map(CityModel.fromJson).toList(),
          );
        },
      );
    } catch (_) {
      return null;
    }
  }
}

class HomePayload {
  HomePayload({
    this.courses = const [],
    this.suggestedCourses = const [],
    this.institutes = const [],
    this.categories = const [],
    this.cities = const [],
  });

  final List<CourseModel> courses;
  final List<CourseModel> suggestedCourses;
  final List<InstituteModel> institutes;
  final List<CategoryModel> categories;
  final List<CityModel> cities;
}
