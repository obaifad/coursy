import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/paginated_fetch.dart';

/// اهتمامات التسجيل/البروفايل — من `/api/categories`: الخادم يبني «مقترح لك» من التصنيفات
/// ويقبل `preferred_categories` فقط (معرّفات الـ tags قائمة مختلفة).
class InterestRepository extends GetxService {
  InterestRepository(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> fetchInterests({int perPage = 50}) async {
    // all=1: كل التصنيفات حتى التي بلا دورات (courses_count: 0). اهتمامات الطالب يجب أن تشمل كل التصنيفات
    // لأن إشعارات الدورات الجديدة تُرسل حسبها؛ بدونه يعرض الخادم التصنيفات التي فيها دورات فقط.
    return fetchAllPages(
      _client,
      ApiEndpoints.categories,
      CategoryModel.fromJson,
      perPage: perPage,
      query: const {'all': 1},
    );
  }
}
