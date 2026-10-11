import 'package:get/get.dart';

abstract final class EducationLevelUtils {
  static const bachelorAndAbove = {'Bachelor', 'Master', 'PhD'};

  static const canonicalLevels = ['High School', 'Diploma', 'Bachelor', 'Master', 'PhD'];

  static bool requiresUniversityFields(String? level) {
    return level != null && bachelorAndAbove.contains(normalize(level));
  }

  /// يوحّد قيمة المستوى التعليمي القادمة من الـ API مع قيم الـ dropdown.
  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    for (final level in canonicalLevels) {
      if (level.toLowerCase() == value.toLowerCase()) return level;
    }
    final compact = value.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    for (final level in canonicalLevels) {
      if (level.toLowerCase() == compact) return level;
    }
    return value;
  }

  /// النص المترجم للمستوى التعليمي (مشترك بين التسجيل وتعديل الملف الشخصي).
  static String label(String value) {
    switch (value) {
      case 'High School':
        return 'edu_high_school'.tr;
      case 'Diploma':
        return 'edu_diploma'.tr;
      case 'Bachelor':
        return 'edu_bachelor'.tr;
      case 'Master':
        return 'edu_master'.tr;
      case 'PhD':
        return 'edu_phd'.tr;
      default:
        return value;
    }
  }

  /// تاريخ الميلاد بصيغة الـ API: YYYY-MM-DD.
  static String formatApiDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
