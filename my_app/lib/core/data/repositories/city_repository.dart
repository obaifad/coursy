import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';

class CityRepository extends GetxService {
  CityRepository(this._client);

  final ApiClient _client;

  Future<List<CityModel>> fetchCities() async {
    final list = await _client.handle(
      () => _client.get(ApiEndpoints.cities),
      (data) {
        try {
          return extractListMap(data).map(CityModel.fromJson).toList();
        } on FormatException catch (e) {
          throw ApiException(e.message);
        }
      },
    );
    if (list.isEmpty) {
      throw ApiException('لم يتم العثور على مدن — تحقق من الاتصال أو CORS على المتصفح');
    }
    return list;
  }

  Future<CityModel> fetchCityById(int id) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.resourceById(ApiEndpoints.cities, id)),
      (data) {
        final map = extractObjectMap(normalizeApiBody(data));
        if (map == null) throw ApiException('بيانات المدينة غير صالحة');
        return CityModel.fromJson(map);
      },
    );
  }

  Future<PaginatedResult<InstituteModel>> fetchInstitutesByCity(int cityId, {int page = 1, int perPage = 15}) async {
    return _client.handle(
      () => _client.get(
        '${ApiEndpoints.cities}/$cityId/institutes',
        query: {'page': page, 'per_page': perPage},
      ),
      (data) => PaginatedResult<InstituteModel>.fromBody(data, InstituteModel.fromJson),
    );
  }
}
