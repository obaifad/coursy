import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../services/course_rating_service.dart';

/// نطاق البحث — عند [all] لا يُرسل type فيُبحث في الكل.
enum SearchScope {
  all,
  courses,
  institutes,
  instructors,
}

extension SearchScopeApi on SearchScope {
  String? get apiParam {
    switch (this) {
      case SearchScope.all:
        return null;
      case SearchScope.courses:
        return 'courses';
      case SearchScope.institutes:
        return 'institutes';
      case SearchScope.instructors:
        return 'instructors';
    }
  }

  String get labelKey {
    switch (this) {
      case SearchScope.all:
        return 'search_type_all';
      case SearchScope.courses:
        return 'search_type_courses';
      case SearchScope.institutes:
        return 'search_type_institutes';
      case SearchScope.instructors:
        return 'search_type_instructors';
    }
  }

  String get hintKey {
    switch (this) {
      case SearchScope.all:
        return 'search_hint_all';
      case SearchScope.courses:
        return 'search_hint_courses';
      case SearchScope.institutes:
        return 'search_hint_institutes';
      case SearchScope.instructors:
        return 'search_hint_instructors';
    }
  }

  String get descriptionKey {
    switch (this) {
      case SearchScope.all:
        return 'search_scope_desc_all';
      case SearchScope.courses:
        return 'search_scope_desc_courses';
      case SearchScope.institutes:
        return 'search_scope_desc_institutes';
      case SearchScope.instructors:
        return 'search_scope_desc_instructors';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchScope.all:
        return Icons.grid_view_rounded;
      case SearchScope.courses:
        return Icons.school_rounded;
      case SearchScope.institutes:
        return Icons.account_balance_rounded;
      case SearchScope.instructors:
        return Icons.person_search_rounded;
    }
  }
}

class SearchRepository extends GetxService {
  SearchRepository(this._client, this._ratingService);

  final ApiClient _client;
  final CourseRatingService _ratingService;

  Future<SearchResult> search({
    required String query,
    SearchScope scope = SearchScope.all,
    int limit = 12,
    int? categoryId,
    int? cityId,
    String? level,
    String? studyType,
    int? instituteId,
    bool? featured,
    bool? verified,
  }) async {
    final cappedLimit = limit.clamp(1, 50);
    final params = <String, dynamic>{
      'q': query,
      'limit': cappedLimit,
      if (scope.apiParam != null) 'type': scope.apiParam,
      if (categoryId != null) 'category_id': categoryId,
      if (cityId != null) 'city_id': cityId,
      if (level != null && level.isNotEmpty) 'level': level,
      if (studyType != null && studyType.isNotEmpty) 'study_type': studyType,
      if (instituteId != null) 'institute_id': instituteId,
      if (featured == true) 'featured': 1,
      if (verified == true) 'verified': 1,
    };

    final result = await _client.handle(
      () => _client.get(ApiEndpoints.search, query: params),
      (data) {
        final normalized = normalizeApiBody(data);
        if (normalized is! Map<String, dynamic>) {
          return SearchResult();
        }
        final map = extractObjectMap(normalized) ?? normalized;

        final courseMaps = map.containsKey('courses') ? extractListMap(map['courses']) : const <Map<String, dynamic>>[];
        final instituteMaps = _extractInstituteMaps(map);
        final instructorMaps =
            map.containsKey('instructors') ? extractListMap(map['instructors']) : const <Map<String, dynamic>>[];

        return SearchResult(
          courses: courseMaps.map(CourseModel.fromJson).toList(),
          institutes: instituteMaps.map(InstituteModel.fromJson).toList(),
          instructors: instructorMaps.map(InstructorModel.fromJson).toList(),
        );
      },
    );

    return _enrichSearchResult(result);
  }

  List<Map<String, dynamic>> _extractInstituteMaps(Map<String, dynamic> map) {
    if (map.containsKey('institutes')) {
      return extractListMap(map['institutes']);
    }

    final results = map['results'];
    if (results is List) {
      final institutes = <Map<String, dynamic>>[];
      for (final item in results) {
        if (item is! Map) continue;
        final entry = Map<String, dynamic>.from(item);
        final type = entry['type']?.toString().toLowerCase();
        if (type != null && type != 'institute' && type != 'institutes') continue;
        final payload = entry['item'] ?? entry['model'] ?? entry['data'] ?? entry;
        final coerced = coerceMap(payload);
        if (coerced != null) institutes.add(coerced);
      }
      if (institutes.isNotEmpty) return institutes;
    }

    return const [];
  }

  Future<SearchResult> _enrichSearchResult(SearchResult result) async {
    final courses = result.courses.isEmpty
        ? result.courses
        : await _ratingService.enrich(result.courses);
    final institutes = result.institutes.isEmpty
        ? result.institutes
        : await _enrichInstitutes(result.institutes, searchCourses: result.courses);

    return SearchResult(
      courses: courses,
      institutes: institutes,
      instructors: result.instructors,
    );
  }

  /// استكمال عدد الدورات/التقييم/اللوغو من كاش قائمة المعاهد (بدون طلبات إضافية).
  Future<List<InstituteModel>> _enrichInstitutes(
    List<InstituteModel> institutes, {
    List<CourseModel> searchCourses = const [],
  }) async {
    var enriched = await _ratingService.enrichInstitutes(institutes);
    if (searchCourses.isEmpty) return enriched;

    return enriched
        .map((institute) {
          if (institute.coursesCount > 0) return institute;
          final fromSearch = searchCourses.where((course) => course.instituteId == institute.id).length;
          if (fromSearch <= 0) return institute;
          return institute.copyWith(coursesCount: fromSearch);
        })
        .toList(growable: false);
  }
}

class SearchResult {
  SearchResult({
    this.courses = const [],
    this.institutes = const [],
    this.instructors = const [],
  });

  final List<CourseModel> courses;
  final List<InstituteModel> institutes;
  final List<InstructorModel> instructors;

  int get totalCourses => courses.length;
  int get totalInstitutes => institutes.length;
  int get totalInstructors => instructors.length;

  bool get isEmpty => courses.isEmpty && institutes.isEmpty && instructors.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
