import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../network/paginated_fetch.dart';

class CategoryRepository extends GetxService {
  CategoryRepository(this._client);

  final ApiClient _client;

  /// كل التصنيفات/الاهتمامات — يجلب كل الصفحات حتى total من الـ API (أي عدد).
  Future<List<CategoryModel>> fetchCategories({int perPage = 50}) async {
    return fetchAllPages(
      _client,
      ApiEndpoints.categories,
      CategoryModel.fromJson,
      perPage: perPage,
    );
  }

  Future<Map<String, dynamic>?> fetchCategoryById(int id) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.categoryById(id)),
      (data) {
        final map = normalizeApiBody(data);
        if (map is Map<String, dynamic>) return map;
        return null;
      },
    );
  }
}
