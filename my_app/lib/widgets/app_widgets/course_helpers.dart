part of '../app_widgets.dart';

/// أيقونة التصنيف من اسمه (عربي أو إنجليزي) — مشتركة بين بطاقات الدورات.
IconData courseCategoryIcon(String? category, {bool rounded = false}) {
  final name = (category ?? '').toLowerCase();
  if (name.contains('لغ') || name.contains('lang')) {
    return rounded ? Icons.translate_rounded : Icons.translate_outlined;
  }
  if (name.contains('تصم') || name.contains('design')) return Icons.palette_outlined;
  if (name.contains('أعمال') || name.contains('business')) return Icons.business_center_outlined;
  if (name.contains('برمج') || name.contains('program')) {
    return rounded ? Icons.code_rounded : Icons.code_outlined;
  }
  return rounded ? Icons.school_rounded : Icons.school_outlined;
}

/// ألوان التصنيف للبطاقات: تدرّج الجزء الملوّن ([c1]→[c2])، ولون النص على الأبيض ([ink])، وخلفية فاتحة ([tint]).
typedef CourseCategoryPalette = ({Color c1, Color c2, Color ink, Color tint});

CourseCategoryPalette courseCategoryPalette(String? category) {
  final name = (category ?? '').toLowerCase();
  bool has(List<String> words) => words.any(name.contains);
  if (has(['تصم', 'design'])) {
    return (
      c1: const Color(0xFFEC4899),
      c2: const Color(0xFF8B5CF6),
      ink: const Color(0xFF9D174D),
      tint: const Color(0xFFFCE7F3),
    );
  }
  if (has(['لغ', 'lang'])) {
    return (
      c1: const Color(0xFFF59E0B),
      c2: const Color(0xFFF97316),
      ink: const Color(0xFF9A3412),
      tint: const Color(0xFFFFEDD5),
    );
  }
  if (has(['أعمال', 'business', 'تسويق', 'marketing', 'مال', 'financ'])) {
    return (
      c1: const Color(0xFF0EA5E9),
      c2: const Color(0xFF6366F1),
      ink: const Color(0xFF1E40AF),
      tint: const Color(0xFFDBEAFE),
    );
  }
  if (has(['عمار', 'هندس', 'architect', 'engineer'])) {
    return (
      c1: const Color(0xFF14B8A6),
      c2: const Color(0xFF0EA5E9),
      ink: const Color(0xFF115E59),
      tint: const Color(0xFFCCFBF1),
    );
  }
  return (c1: AppColors.primary, c2: AppColors.primaryStrong, ink: AppColors.primaryInk, tint: const Color(0xFFECEBFF));
}

IconData courseStudyTypeIcon(String studyType) {
  final probe = studyType.toLowerCase();
  if (probe.contains('أون') || probe.contains('online') || probe.contains('عن')) {
    return Icons.computer_rounded;
  }
  if (probe.contains('هجين') || probe.contains('مختلط') || probe.contains('hybrid') || probe.contains('mixed')) {
    return Icons.devices_rounded;
  }
  if (probe.contains('حضور') || probe.contains('offline')) {
    return Icons.location_city_rounded;
  }
  return Icons.cast_for_education_outlined;
}

const double _kCourseCardRadius = CourseCardMetrics.cardRadius;

const List<BoxShadow> _courseCardShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 6)),
  BoxShadow(color: AppColors.shadowNeutralSoft, blurRadius: 4, offset: Offset(0, 2)),
];

bool _isNewCourse(CourseModel course) {
  final raw = course.startDate;
  if (raw == null || raw.isEmpty) return false;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return false;
  return DateTime.now().difference(parsed).inDays.abs() <= 30;
}

String? _coursePromoBadge(CourseModel course) {
  if (course.isFeatured) return 'course_badge_bestseller'.tr;
  final max = course.maxStudents;
  final enrolled = course.enrolledCountForCapacity;
  if (max != null && max > 0) {
    final remaining = max - enrolled;
    if (remaining > 0 && remaining <= 5) return 'course_badge_limited_seats'.tr;
  }
  if (_isNewCourse(course)) return 'course_badge_new'.tr;
  if (enrolled >= 10 || (max != null && max > 0 && enrolled >= (max * 0.75).ceil())) {
    return 'course_badge_popular'.tr;
  }
  return null;
}
