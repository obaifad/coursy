import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../config/api_config.dart';
import '../locale/app_translations.dart';
import '../locale/locale_controller.dart';
import '../push/push_local_notifications.dart';
import '../storage/enrollment_status_store.dart';
import '../storage/session_keys.dart';
import 'enrollment_status_change.dart';

const enrollmentBackgroundTask = 'enrollmentBackgroundCheck';

@pragma('vm:entry-point')
void enrollmentBackgroundCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != enrollmentBackgroundTask) return true;
    try {
      await BackgroundEnrollmentChecker.run();
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// فحص حالة التسجيل في الخلفية — بديل عندما FCM لا يصل.
abstract final class BackgroundEnrollmentChecker {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true, migrateWithBackup: false, storageNamespace: 'com.coursy.auth'),
  );

  static Future<void> run() async {
    // لا نستخدم GetStorage هنا: الكتابة من isolate ثانٍ تمسح بيانات التطبيق الرئيسي.
    await PushLocalNotifications.loadUserEnabled();
    await PushLocalNotifications.ensureInitialized();

    final token = await _secure.read(key: SessionKeys.accessToken);
    final studentId = int.tryParse(await _secure.read(key: SessionKeys.studentId) ?? '');
    if (token == null || token.isEmpty || studentId == null || studentId <= 0) return;

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        // 4xx (مثل 401 عند انتهاء الجلسة) لا يُرمى كخطأ — إعادة المحاولة لن تفيد.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final response = await dio.get<dynamic>('/student/enrollments', queryParameters: {'per_page': 100});
    if (response.statusCode != 200) return;

    final enrollments = _extractEnrollments(response.data);
    final statuses = await EnrollmentStatusStore.loadStatuses(studentId);
    final delivered = await EnrollmentStatusStore.loadDelivered(studentId);
    final texts = await _loadTexts();

    String text(EnrollmentStatusChange change, String courseTitle) {
      final generic = texts[change.genericBodyKey] ?? '';
      if (courseTitle.isEmpty) return generic;
      return (texts[change.bodyKey] ?? generic).replaceAll('@course', '"$courseTitle"');
    }

    for (final row in enrollments) {
      final id = _parseInt(row['id']);
      if (id == null || id <= 0) continue;

      final next = row['status']?.toString().toLowerCase() ?? '';
      final change = EnrollmentStatusChange.detect(statuses[id], next);
      if (change != null) {
        final key = change.deliveredKey(id);
        if (!delivered.contains(key)) {
          delivered.add(key);
          final courseId =
              _parseInt(row['course_id']) ?? (row['course'] is Map ? _parseInt((row['course'] as Map)['id']) : null);
          final coursePart = courseId == null ? '' : '&course_id=$courseId';
          await PushLocalNotifications.showRaw(
            id: change.notificationId(id),
            title: texts[change.titleKey] ?? '',
            body: text(change, _courseTitle(row)),
            payload: 'type=${change.type}&enrollment_id=$id$coursePart',
            requirePermission: false,
          );
        }
      }

      statuses[id] = next;
    }

    await EnrollmentStatusStore.persistStatuses(statuses, studentId);
    await EnrollmentStatusStore.persistDelivered(delivered, studentId);
  }

  /// وصل إشعار FCM بتغيّر الحالة والتطبيق في الخلفية (النظام عرضه): نسجّله «مُبلَّغاً عنه» كي لا يكرره
  /// هذا الفحص أو التطبيق عند فتحه بإشعار محلي ثانٍ لنفس التغيّر.
  static Future<void> recordDeliveredPush(Map<String, dynamic> data) async {
    final change = EnrollmentStatusChange.fromNotificationType(data['type']?.toString());
    final enrollmentId = _parseInt(data['enrollment_id']);
    if (change == null || enrollmentId == null || enrollmentId <= 0) return;
    final studentId = int.tryParse(await _secure.read(key: SessionKeys.studentId) ?? '');
    if (studentId == null || studentId <= 0) return;
    await EnrollmentStatusStore.persistDelivered({change.deliveredKey(enrollmentId)}, studentId);
  }

  /// نصوص الإشعارات بلغة التطبيق — لا توجد ترجمات GetX داخل الـ isolate الخلفي،
  /// فنقرأ اللغة المحفوظة ونأخذ النصوص من ملف الترجمة مباشرة.
  static Future<Map<String, String>> _loadTexts() async {
    var code = 'ar';
    try {
      code = await SharedPreferencesAsync().getString(LocaleController.backgroundLocaleKey) ?? 'ar';
    } catch (_) {}
    final keys = AppTranslations().keys;
    return keys[code] ?? keys['ar']!;
  }

  static List<Map<String, dynamic>> _extractEnrollments(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) {
        return inner.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  static String _courseTitle(Map<String, dynamic> row) {
    if (row['course'] is Map) {
      final title = (row['course'] as Map)['title']?.toString().trim();
      if (title != null && title.isNotEmpty) return title;
    }
    return row['course_title']?.toString().trim() ?? '';
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
