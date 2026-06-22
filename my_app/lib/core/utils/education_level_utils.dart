abstract final class EducationLevelUtils {
  static const bachelorAndAbove = {'Bachelor', 'Master', 'PhD'};

  static bool requiresUniversityFields(String? level) {
    return level != null && bachelorAndAbove.contains(level);
  }
}
