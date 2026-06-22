import 'package:get/get.dart';

/// مساعدات تحويل JSON مشتركة (مطابقة لـ Laravel API).
abstract final class JsonHelpers {
  static int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? parseIntOrNull(dynamic value) {
    if (value == null) return null;
    final v = parseInt(value);
    return v == 0 && value != 0 && value != '0' ? null : v;
  }

  static double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// تقييم الدورة من الحقل المباشر أو متوسط التقييمات المضمّنة.
  static double resolveCourseRating(Map<String, dynamic> json, {double fallback = 0}) {
    final direct = parseDoubleOrNull(
      json['average_rating'] ??
          json['rating'] ??
          json['avg_rating'] ??
          json['reviews_average'] ??
          json['averageRating'] ??
          json['reviews_avg'],
    );
    if (direct != null && direct > 0) return direct;

    if (json['reviews'] is List) {
      final reviews = json['reviews'] as List;
      var sum = 0.0;
      var count = 0;
      for (final item in reviews) {
        if (item is Map && item['rating'] != null) {
          sum += parseDouble(item['rating']);
          count++;
        }
      }
      if (count > 0) return sum / count;
    }

    return fallback;
  }

  static bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static String formatSyrianPrice(dynamic price, {dynamic discount}) {
    final discountNum = discount != null ? parseDouble(discount) : 0;
    final priceNum = parseDouble(price);
    final value = discountNum > 0 ? discountNum : priceNum;
    if (value <= 0) return '—';
    return '${value.toStringAsFixed(0)} ${'currency_syp'.tr}';
  }

  static String levelLabel(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return 'level_beginner'.tr;
      case 'intermediate':
        return 'level_intermediate'.tr;
      case 'advanced':
        return 'level_advanced'.tr;
      default:
        return level ?? '—';
    }
  }

  static String studyTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'online':
        return 'study_online'.tr;
      case 'offline':
        return 'study_offline'.tr;
      case 'hybrid':
        return 'study_hybrid'.tr;
      default:
        return type ?? '—';
    }
  }

  static String durationLabel({int? hours, int? sessions}) {
    if (hours != null && hours > 0) return 'hours_unit'.trParams({'n': '$hours'});
    if (sessions != null && sessions > 0) return 'sessions_unit'.trParams({'n': '$sessions'});
    return '—';
  }

  static String weekdayLabel(String? day) {
    switch (day?.toLowerCase()) {
      case 'monday':
        return 'day_monday'.tr;
      case 'tuesday':
        return 'day_tuesday'.tr;
      case 'wednesday':
        return 'day_wednesday'.tr;
      case 'thursday':
        return 'day_thursday'.tr;
      case 'friday':
        return 'day_friday'.tr;
      case 'saturday':
        return 'day_saturday'.tr;
      case 'sunday':
        return 'day_sunday'.tr;
      default:
        return day ?? '—';
    }
  }

  static String formatDisplayDate(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    final parts = value.split('T').first.split('-');
    if (parts.length != 3) return value;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  /// يحلّل تاريخاً من API (YYYY-MM-DD أو ISO-8601) للمقارنة اليومية.
  static DateTime? tryParseDateOnly(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final datePart = value.trim().split('T').first.trim();
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(value.trim());
  }

  static String localizedText(Map<String, dynamic> json, String key) {
    final isAr = Get.locale?.languageCode == 'ar';
    final primary = json[isAr ? '${key}_ar' : '${key}_en']?.toString();
    final secondary = json[isAr ? '${key}_en' : '${key}_ar']?.toString();
    if (primary != null && primary.trim().isNotEmpty) return primary.trim();
    final direct = json[key]?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    if (secondary != null && secondary.trim().isNotEmpty) return secondary.trim();
    return '';
  }
}
