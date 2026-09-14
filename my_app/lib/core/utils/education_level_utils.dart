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
}
