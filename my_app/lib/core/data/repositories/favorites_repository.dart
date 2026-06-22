import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/favorite_model.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';
import '../../services/student_id_resolver.dart';

class FavoritesRepository extends GetxService {
  FavoritesRepository(this._client, this._studentIdResolver);

  final ApiClient _client;
  final StudentIdResolver _studentIdResolver;

  void _log(String action, dynamic body, {String? path}) {
    debugPrint('');
    debugPrint('══════════════ FAVORITES ($action) ══════════════');
    if (path != null) debugPrint('Path: $path');
    debugPrint(body.toString());
    debugPrint('══════════════════════════════════════════════════');
    debugPrint('');
  }

  Future<List<FavoriteModel>> fetchMine() async {
    return _client.handle(
      () => _client.get(ApiEndpoints.studentFavorites),
      (data) {
        _log('LIST', data, path: ApiEndpoints.studentFavorites);
        final page = PaginatedResult<FavoriteModel>.fromBody(data, FavoriteModel.fromJson);
        return page.items;
      },
    );
  }

  Future<Map<String, dynamic>> addFavorite({
    int? courseId,
    int? instituteId,
    int? instructorId,
  }) async {
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

    return _client.handle(
      () => _client.post(ApiEndpoints.studentFavorites, data: data),
      (raw) {
        final body = normalizeApiBody(raw);
        _log('ADD', body, path: ApiEndpoints.studentFavorites);
        if (body is Map<String, dynamic>) return body;
        return <String, dynamic>{'data': body};
      },
    );
  }

  Future<void> removeFavorite(int favoriteId, {int? courseId}) async {
    ApiException? lastError;

    if (courseId != null) {
      final paths = [
        ApiEndpoints.courseFavorite(courseId),
        ApiEndpoints.studentCourseFavorite(courseId),
      ];
      for (final path in paths) {
        try {
          await _client.handle(
            () => _client.delete(path),
            (raw) {
              _log('REMOVE', normalizeApiBody(raw), path: path);
              return null;
            },
          );
          return;
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          rethrow;
        }
      }
    }

    final paths = [
      ApiEndpoints.resourceById(ApiEndpoints.studentFavorites, favoriteId),
    ];

    for (final path in paths) {
      try {
        await _client.handle(
          () => _client.delete(path),
          (raw) {
            _log('REMOVE', normalizeApiBody(raw), path: path);
            return null;
          },
        );
        return;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }

    throw lastError ?? ApiException('تعذر إزالة العنصر من المفضلة');
  }

  Future<Map<String, dynamic>> _postCourseFavorite(int courseId) async {
    final paths = [
      ApiEndpoints.courseFavorite(courseId),
      ApiEndpoints.studentCourseFavorite(courseId),
    ];
    ApiException? lastError;

    for (final path in paths) {
      try {
        return await _client.handle(
          () => _client.post(path, data: const <String, dynamic>{}),
          (raw) {
            final body = normalizeApiBody(raw);
            _log('ADD', body, path: path);
            if (body is Map<String, dynamic>) return body;
            return <String, dynamic>{'data': body};
          },
        );
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }

    throw lastError ?? ApiException('تعذر إضافة الدورة إلى المفضلة');
  }
}

