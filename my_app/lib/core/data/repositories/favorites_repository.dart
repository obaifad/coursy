import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../models/favorite_model.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../network/paginated_fetch.dart';
import '../../services/student_id_resolver.dart';

class FavoritesRepository extends GetxService {
  FavoritesRepository(this._client, this._studentIdResolver);

  final ApiClient _client;
  final StudentIdResolver _studentIdResolver;

  void _log(String action, dynamic body, {String? path}) {
    if (path != null) AppDebugLog.repo('Favorites', '$action $path');
    AppDebugLog.repo('Favorites', body.toString());
  }

  /// كل الصفحات — الخادم يرقّم 15 عنصراً في الصفحة، فالصفحة الأولى وحدها تُسقط بقية المفضلة.
  Future<List<FavoriteModel>> fetchMine() async {
    final items = await fetchAllPages(_client, ApiEndpoints.studentFavorites, FavoriteModel.fromJson, strict: false);
    _log('LIST', '${items.length} items', path: ApiEndpoints.studentFavorites);
    return items;
  }

  Future<Map<String, dynamic>> addFavorite({int? courseId, int? instituteId, int? instructorId}) async {
    if (courseId != null) {
      return _postCourseFavorite(courseId);
    }

    final data = <String, dynamic>{
      if (instituteId != null) 'institute_id': instituteId,
      if (instructorId != null) 'instructor_id': instructorId,
    };

    try {
      final studentId = await _studentIdResolver.resolve();
      data['student_id'] = studentId;
    } catch (_) {}

    return _client.handle(() => _client.post(ApiEndpoints.studentFavorites, data: data), (raw) {
      final body = normalizeApiBody(raw);
      _log('ADD', body, path: ApiEndpoints.studentFavorites);
      if (body is Map<String, dynamic>) return body;
      return <String, dynamic>{'data': body};
    });
  }

  /// الدورة: `DELETE /courses/{id}/favorite` فقط (كانت تُجرَّب بعده مسارات غير موجودة عند 404/405).
  /// غير الدورات (معهد/مدرّس) تُحذف بمعرّف المفضلة.
  Future<void> removeFavorite(int favoriteId, {int? courseId}) async {
    final path = courseId != null
        ? ApiEndpoints.courseFavorite(courseId)
        : ApiEndpoints.resourceById(ApiEndpoints.studentFavorites, favoriteId);
    await _client.handle(() => _client.delete(path), (raw) {
      _log('REMOVE', normalizeApiBody(raw), path: path);
      return null;
    });
  }

  /// `POST /courses/{id}/favorite` فقط (المسار البديل `/student/courses/{id}/favorite` غير موجود على الخادم).
  Future<Map<String, dynamic>> _postCourseFavorite(int courseId) {
    final path = ApiEndpoints.courseFavorite(courseId);
    return _client.handle(() => _client.post(path, data: const <String, dynamic>{}), (raw) {
      final body = normalizeApiBody(raw);
      _log('ADD', body, path: path);
      if (body is Map<String, dynamic>) return body;
      return <String, dynamic>{'data': body};
    });
  }
}
