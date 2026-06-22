import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import 'reference_repository.dart';

class InstructorRepository extends GetxService {
  InstructorRepository(this._client, this._referenceRepository);

  final ApiClient _client;
  final ReferenceRepository _referenceRepository;

  static int? specializationIdFromFilterKey(String? key) {
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('spec:')) return int.tryParse(key.substring(5));
    return null;
  }

  /// فلاتر التخصص من الـ API مع عدّ المدرّسين الخصوصيين لكل تخصص.
  Future<List<InstructorSubjectModel>> fetchInstructorSubjectFilters() async {
    try {
      final specs = await _referenceRepository.fetchInstructorSpecializations();
      if (specs.isEmpty) return fetchInstructorSubjects();

      final counts = await _countPrivateInstructorsBySpecializationId();
      return specs
          .map(
            (spec) => spec.toSubjectFilter().copyWith(
                  instructorsCount: counts[spec.id] ?? 0,
                ),
          )
          .toList();
    } catch (_) {
      return fetchInstructorSubjects();
    }
  }

  Future<Map<int, int>> _countPrivateInstructorsBySpecializationId() async {
    final counts = <int, int>{};
    var page = 1;
    var hasMore = true;
    while (hasMore) {
      final result = await fetchInstructorsPage(page: page, perPage: 50, isPrivate: true);
      for (final instructor in result.items) {
        final id = instructor.specializationId;
        if (id == null) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      hasMore = result.hasMore;
      page++;
      if (page > 20) break;
    }
    return counts;
  }

  Future<PaginatedResult<InstructorModel>> fetchInstructorsPage({
    int page = 1,
    int perPage = 15,
    bool? isPrivate,
    int? instituteId,
    String? subjectKey,
    int? specializationId,
  }) async {
    final resolvedSpecId = specializationId ?? specializationIdFromFilterKey(subjectKey);
    final result = await _client.handle(
      () => _client.get(
        ApiEndpoints.instructors,
        query: {
          'page': page,
          'per_page': perPage,
          if (instituteId != null) 'institute_id': instituteId,
          if (isPrivate == true) 'is_private': 1,
          if (resolvedSpecId != null) 'specialization_id': resolvedSpecId,
        },
      ),
      (data) => PaginatedResult<InstructorModel>.fromBody(data, InstructorModel.fromJson),
    );

    var items = result.items;
    if (isPrivate == true) {
      items = items.where((item) => item.isPrivate).toList();
    }
    if (resolvedSpecId != null) {
      items = items.where((item) => item.specializationId == resolvedSpecId).toList();
    } else if (subjectKey != null && subjectKey.isNotEmpty) {
      items = items.where((item) => item.subjectKey == subjectKey).toList();
    }

    if (isPrivate != true && subjectKey == null && resolvedSpecId == null) return result;

    return PaginatedResult<InstructorModel>(
      items: items,
      currentPage: result.currentPage,
      lastPage: result.lastPage,
      total: items.length < result.items.length ? items.length : result.total,
      hasMore: result.hasMore,
    );
  }

  /// يجمع المواد الفريدة من المدرّسين الخصوصيين (specialization).
  Future<List<InstructorSubjectModel>> fetchInstructorSubjects({bool privateOnly = true}) async {
    final counts = <String, _SubjectAccumulator>{};
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final result = await fetchInstructorsPage(page: page, perPage: 50, isPrivate: privateOnly ? true : null);
      for (final instructor in result.items) {
        if (privateOnly && !instructor.isPrivate) continue;
        final key = instructor.subjectKey;
        if (key.isEmpty) continue;
        final entry = counts.putIfAbsent(
          key,
          () => _SubjectAccumulator(
            key: key,
            nameEn: instructor.specializationEn,
            nameAr: instructor.specializationAr,
            localized: instructor.specialization,
          ),
        );
        entry.count++;
      }
      hasMore = result.hasMore;
      page++;
      if (page > 20) break;
    }

    final subjects = counts.values
        .map(
          (e) => InstructorSubjectModel(
            key: e.key,
            name: e.displayName,
            nameEn: e.nameEn,
            nameAr: e.nameAr,
            instructorsCount: e.count,
          ),
        )
        .toList()
      ..sort((a, b) {
        final byCount = b.instructorsCount.compareTo(a.instructorsCount);
        if (byCount != 0) return byCount;
        return a.name.compareTo(b.name);
      });

    return subjects;
  }

  /// يحمّل كل المدرّسين لمادة معيّنة (مع pagination محلي).
  Future<List<InstructorModel>> fetchInstructorsBySubject({
    required String subjectKey,
    bool privateOnly = true,
  }) async {
    final specId = specializationIdFromFilterKey(subjectKey);
    final all = <InstructorModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final result = await fetchInstructorsPage(
        page: page,
        perPage: 50,
        isPrivate: privateOnly ? true : null,
        subjectKey: specId == null ? subjectKey : null,
        specializationId: specId,
      );
      all.addAll(result.items);
      hasMore = result.hasMore;
      page++;
      if (page > 20) break;
    }

    return all;
  }

  Future<InstructorModel> fetchInstructorById(int id) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.instructorById(id)),
      (data) {
        final map = extractObjectMap(data);
        if (map == null) {
          throw Exception('instructor_invalid_data'.tr);
        }
        return InstructorModel.fromJson(map);
      },
    );
  }

  Future<PaginatedResult<CourseModel>> fetchInstructorCoursesPage({
    required int instructorId,
    int page = 1,
    int perPage = 15,
  }) async {
    return _client.handle(
      () => _client.get(
        ApiEndpoints.instructorCourses(instructorId),
        query: {'page': page, 'per_page': perPage},
      ),
      (data) => PaginatedResult<CourseModel>.fromBody(data, CourseModel.fromJson),
    );
  }

  Future<List<InstructorModel>> fetchInstructors({
    int? instituteId,
    bool? isPrivate,
    String? subjectKey,
    int? specializationId,
  }) async {
    final result = await fetchInstructorsPage(
      page: 1,
      perPage: 50,
      instituteId: instituteId,
      isPrivate: isPrivate,
      subjectKey: subjectKey,
      specializationId: specializationId,
    );
    return result.items;
  }
}

class _SubjectAccumulator {
  _SubjectAccumulator({
    required this.key,
    this.nameEn,
    this.nameAr,
    this.localized,
  });

  final String key;
  String? nameEn;
  String? nameAr;
  String? localized;
  int count = 0;

  String get displayName {
    final isAr = Get.locale?.languageCode == 'ar';
    if (isAr) {
      if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
      if (localized != null && localized!.isNotEmpty) return localized!;
      if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    } else {
      if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
      if (localized != null && localized!.isNotEmpty) return localized!;
      if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    }
    return key;
  }
}
