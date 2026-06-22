import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';

class NotificationRepository extends GetxService {
  NotificationRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResult<NotificationModel>> fetchNotificationsPage({int page = 1, int perPage = 15}) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.studentNotifications, query: {'page': page, 'per_page': perPage}),
      (data) => PaginatedResult<NotificationModel>.fromBody(data, NotificationModel.fromJson),
    );
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    return _client.handle(
      () => _client.get(ApiEndpoints.studentNotifications),
      (data) => extractListMap(data).map(NotificationModel.fromJson).toList(),
    );
  }
}
