import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';

class EnrollmentRepository extends GetxService {
  EnrollmentRepository(this._client);

  final ApiClient _client;

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

  /// الخادم يأخذ الطالب من التوكن ويحدد حالة التسجيل والدفع بنفسه — لا يُرسل شيء في الجسم.
  /// 201 لتسجيل جديد، و200 إن كان الطالب مسجلاً من قبل.
  Future<EnrollmentModel> enrollInCourse(int courseId) {
    return _client.handle(
      () => _client.post(ApiEndpoints.enrollByCourse(courseId), data: const <String, dynamic>{}),
      _parseEnrollment,
    );
  }

  Future<EnrollmentModel> cancelEnrollment(int enrollmentId) async {
    return _client.handle(
      () => _client.post(ApiEndpoints.studentCancelEnrollment(enrollmentId), data: const <String, dynamic>{}),
      _parseEnrollment,
    );
  }
}
