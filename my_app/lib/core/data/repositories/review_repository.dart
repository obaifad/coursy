import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';

class ReviewRepository extends GetxService {
  ReviewRepository(this._client);

  final ApiClient _client;

  void _log(String action, dynamic body, {String? path}) {
    if (path != null) AppDebugLog.repo('Reviews', '$action $path');
    AppDebugLog.repo('Reviews', body.toString());
  }

  /// تقييمات عامة بلا توكن من النقاط المخصّصة (`/courses|instructors|institutes/{id}/reviews`).
  /// الرد ترقيم Laravel في المستوى الأعلى (`data`, `current_page`, `last_page`) — نقرأ كل الصفحات.
  Future<List<ReviewModel>> fetchReviews({int? courseId, int? instituteId, int? instructorId}) async {
    final String path;
    if (courseId != null) {
      path = ApiEndpoints.courseReviews(courseId);
    } else if (instructorId != null) {
      path = ApiEndpoints.instructorReviews(instructorId);
    } else if (instituteId != null) {
      path = ApiEndpoints.instituteReviews(instituteId);
    } else {
      return const [];
    }

    final all = <ReviewModel>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = await _client.handle(() => _client.get(path, query: {'page': page}), (data) {
        _log('LIST', data, path: '$path?page=$page');
        final parsed = PaginatedResult<ReviewModel>.fromBody(data, ReviewModel.fromJson);
        return parsed;
      });
      all.addAll(result.items);
      // الخادم قد لا يرسل next_page_url؛ current_page/last_page يكفيان.
      final more = result.hasMore || result.currentPage < result.lastPage;
      if (!more || result.items.isEmpty) break;
    }
    return all;
  }

  /// حدّ أمان لعدد الصفحات (التقييمات تُعرض كلها في تبويب واحد).
  static const _maxPages = 10;

  /// تقييم المعهد بالنجوم فقط (لا تعليق مكتوب في التطبيق). إرسال ثانٍ يعدّل تقييم الطالب بدل إضافة آخر
  /// (الخادم يحفظ تقييماً واحداً لكل طالب). التقييم في جسم JSON، لا في الرابط كما في الدورة.
  Future<ReviewModel> submitInstituteReview({required int instituteId, required int rating}) {
    final safeRating = rating.clamp(1, 5);
    final path = ApiEndpoints.instituteReviews(instituteId);
    return _client.handle(() => _client.post(path, data: {'rating': safeRating}), (raw) {
      final body = normalizeApiBody(raw);
      _log('SUBMIT', body, path: path);
      final map = extractObjectMap(body) ?? (body is Map<String, dynamic> ? body : <String, dynamic>{});
      if (map.isEmpty) {
        return ReviewModel(id: 0, rating: safeRating, comment: '', studentName: 'review_you'.tr, type: 'institute');
      }
      return ReviewModel.fromJson(map);
    });
  }

  /// يحذف تقييم الطالب للمعهد (204 بلا جسم).
  Future<void> deleteMyInstituteReview(int instituteId) {
    final path = ApiEndpoints.myInstituteReview(instituteId);
    return _client.handle(() => _client.delete(path), (raw) => _log('DELETE', raw, path: path));
  }

  /// تقييم الدورة بالنجوم فقط (`rating` في الرابط كما يتوقّعه الخادم). تقييم المدرّس قراءة فقط.
  Future<ReviewModel> submitReview({required int courseId, required int rating}) {
    final safeRating = rating.clamp(1, 5);
    final path = '${ApiEndpoints.courseReviews(courseId)}?rating=$safeRating';
    return _client.handle(() => _client.post(path, data: const <String, dynamic>{}), (raw) {
      final body = normalizeApiBody(raw);
      _log('SUBMIT', body, path: path);
      final map = extractObjectMap(body) ?? (body is Map<String, dynamic> ? body : <String, dynamic>{});
      if (map.isEmpty) {
        return ReviewModel(id: 0, rating: safeRating, comment: '', studentName: 'review_you'.tr);
      }
      return ReviewModel.fromJson(map);
    });
  }

  /// إبلاغ عن تقييم مسيء (سياسة Google Play للمحتوى من المستخدمين). يُرجع رسالة الخادم إن وُجدت.
  Future<String?> reportReview(int reviewId, {required String reason}) {
    final path = ApiEndpoints.reviewReport(reviewId);
    return _client.handle(() => _client.post(path, data: {'reason': reason}), (raw) {
      final body = normalizeApiBody(raw);
      _log('REPORT', body, path: path);
      final message = body is Map ? body['message']?.toString().trim() : null;
      return (message == null || message.isEmpty) ? null : message;
    });
  }
}
