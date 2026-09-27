import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
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
    AppDebugLog.repo('Enroll', '$action ${body.toString()}');
  }

  EnrollmentModel _parseEnrollment(dynamic body) {
    final normalized = normalizeApiBody(body);
    _log('RESPONSE', normalized);
    final map = extractObjectMap(normalized);
    if (map != null) return EnrollmentModel.fromJson(map);
    if (normalized is Map<String, dynamic>) return EnrollmentModel.fromJson(normalized);
    throw ApiException('error_invalid_server_response'.tr);
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

  Future<EnrollmentModel> enrollInCourse(int courseId) async {
    final studentId = await _studentIdResolver.resolve();
    // TODO(backend): حالة التسجيل والدفع يجب أن يحددها الخادم ويتجاهل القيم القادمة من التطبيق.
    // تبقى هنا لأن الخادم الحالي قد يشترطها في التحقق — احذفها بعد تأكيد مطوّر الخادم.
    final body = <String, dynamic>{
      'course_id': courseId,
      'student_id': studentId,
      'status': 'pending',
      'payment_status': 'unpaid',
    };

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
      () => _client.post(ApiEndpoints.studentCancelEnrollment(enrollmentId), data: const <String, dynamic>{}),
      _parseEnrollment,
    );
  }
}
