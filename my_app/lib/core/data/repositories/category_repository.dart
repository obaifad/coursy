import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';

class CategoryRepository extends GetxService {
  CategoryRepository(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> fetchCategories() async {
    return _client.handle(
      () => _client.get(ApiEndpoints.categories),
      (data) => extractListMap(data).map(CategoryModel.fromJson).toList(),
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
