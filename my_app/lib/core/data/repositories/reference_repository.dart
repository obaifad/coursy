import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/paginated_fetch.dart';

/// جلب القوائم المرجعية: الجامعات والاختصاصات.
class ReferenceRepository extends GetxService {
  ReferenceRepository(this._client);

  final ApiClient _client;

  Future<List<NamedEntity>> fetchUniversities() async {
    return fetchAllPages(
      _client,
      ApiEndpoints.universities,
      NamedEntity.fromJson,
      perPage: 100,
    );
  }

  /// اختصاصات الطلاب من `/specializations?type=student`.
  Future<List<NamedEntity>> fetchStudentSpecializations() async {
    final items = await _fetchSpecializationsByType('student');
    return items.map((s) => s.toNamedEntity()).toList();
  }

  /// للتوافق — يُعيد اختصاصات الطلاب.
  Future<List<NamedEntity>> fetchSpecializations() => fetchStudentSpecializations();

  /// تخصصات المدرّسين من `/specializations?type=instructor`.
  Future<List<SpecializationModel>> fetchInstructorSpecializations() async {
    return _fetchSpecializationsByType('instructor');
  }

  Future<List<SpecializationModel>> _fetchSpecializationsByType(String type) async {
    final normalizedType = type.toLowerCase();
    final items = await fetchAllPages(
      _client,
      ApiEndpoints.specializations,
      SpecializationModel.fromJson,
      query: {'type': normalizedType},
      perPage: 100,
    );
    return items.where((s) => s.type.toLowerCase() == normalizedType).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }
}
