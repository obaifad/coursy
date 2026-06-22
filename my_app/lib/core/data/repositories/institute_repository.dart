import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';

class InstituteRepository extends GetxService {
  InstituteRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResult<InstituteModel>> fetchInstitutesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    final mergedQuery = <String, dynamic>{...?query, 'page': page, 'per_page': perPage};
    return _client.handle(
      () => _client.get(ApiEndpoints.institutes, query: mergedQuery),
      (data) => PaginatedResult<InstituteModel>.fromBody(data, InstituteModel.fromJson),
    );
  }

  Future<List<InstituteModel>> fetchInstitutes({Map<String, dynamic>? query}) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.institutes, query: query),
      (data) => extractListMap(data).map(InstituteModel.fromJson).toList(),
    );
  }

  Future<InstituteModel> fetchInstituteById(int id) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.resourceById(ApiEndpoints.institutes, id)),
      (data) {
        final map = extractObjectMap(data);
        if (map == null) {
          throw Exception('بيانات المعهد غير صالحة');
        }
        return InstituteModel.fromJson(map);
      },
    );
  }
}
