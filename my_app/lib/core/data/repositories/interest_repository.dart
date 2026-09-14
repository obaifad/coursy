import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/paginated_fetch.dart';

/// اهتمامات التسجيل/البروفايل — من `/api/tags` (نفس بيانات [admin/tags](https://coursy.sy/admin/tags)).
class InterestRepository extends GetxService {
  InterestRepository(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> fetchInterests({int perPage = 50}) async {
    return fetchAllPages(
      _client,
      ApiEndpoints.tags,
      CategoryModel.fromJson,
      perPage: perPage,
    );
  }
}
