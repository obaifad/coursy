import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/api_fallback.dart';
import '../../network/json_parser.dart';
import '../../services/student_id_resolver.dart';

class EnrollmentRepository extends GetxService {
  EnrollmentRepository(this._client, this._studentIdResolver);

  final ApiClient _client;
  final StudentIdResolver _studentIdResolver;

  void _log(String action, dynamic body) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('══════════════ ENROLL API ($action) ══════════════');
    debugPrint(body.toString());
    debugPrint('══════════════════════════════════════════════════');
    debugPrint('');
  }

  EnrollmentModel _parseEnrollment(dynamic body) {
    final normalized = normalizeApiBody(body);
    _log('RESPONSE', normalized);
    final map = extractObjectMap(normalized);
    if (map != null) return EnrollmentModel.fromJson(map);
    if (normalized is Map<String, dynamic>) return EnrollmentModel.fromJson(normalized);
    throw ApiException('استجابة التسجيل في الدورة غير صالحة');
  }

  Future<PaginatedResult<EnrollmentModel>> fetchEnrollmentsPage({int page = 1, int perPage = 15}) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.studentEnrollments, query: {'page': page, 'per_page': perPage}),
      (data) => PaginatedResult<EnrollmentModel>.fromBody(data, EnrollmentModel.fromJson),
    );
  }

  Future<List<EnrollmentModel>> fetchEnrollments() async {
    return _client.handle(
      () => _client.get(ApiEndpoints.studentEnrollments),
      (data) => extractListMap(data).map(EnrollmentModel.fromJson).toList(),
    );
  }

  /// عدد التسجيلات المؤكّدة لدورة (بدون المعلّقة).
  Future<int?> countConfirmedEnrollmentsForCourse(int courseId) async {
    if (courseId <= 0) return null;
    try {
      var page = 1;
      var count = 0;
      while (true) {
        final result = await _client.handle(
          () => _client.get(ApiEndpoints.enrollments, query: {'page': page, 'per_page': 100}),
          (data) => PaginatedResult<EnrollmentModel>.fromBody(data, EnrollmentModel.fromJson),
        );
        count += result.items
            .where((e) => e.courseId == courseId && e.countsTowardCourseCapacity)
            .length;
        if (!result.hasMore) break;
        page++;
      }
      return count;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _enrollmentBody(int courseId, int studentId) => {
        'course_id': courseId,
        'student_id': studentId,
        'status': 'pending',
        'payment_status': 'unpaid',
      };

  Future<EnrollmentModel> enrollInCourse(int courseId) async {
    final studentId = await _studentIdResolver.resolve();
    final body = _enrollmentBody(courseId, studentId);

    final attempts = [
      ApiPostAttempt(path: ApiEndpoints.studentEnrollments, data: body),
      ApiPostAttempt(path: ApiEndpoints.studentEnrollCourse(courseId), data: body),
      ApiPostAttempt(path: ApiEndpoints.enrollByCourse(courseId), data: body),
      ApiPostAttempt(path: ApiEndpoints.enrollments, data: body),
      ApiPostAttempt(path: ApiEndpoints.enrollCourseAlt(courseId), data: body),
    ];

    return postFirstSuccess(_client, attempts, _parseEnrollment);
  }

  Future<EnrollmentModel> cancelEnrollment(int enrollmentId) async {
    return _client.handle(
      () => _client.post(
        ApiEndpoints.studentCancelEnrollment(enrollmentId),
        data: const <String, dynamic>{},
      ),
      _parseEnrollment,
    );
  }
}
