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

IconData courseStudyTypeIcon(String studyType) {
  final probe = studyType.toLowerCase();
  if (probe.contains('أون') || probe.contains('online') || probe.contains('عن')) {
    return Icons.computer_rounded;
  }
  if (probe.contains('مختلط') || probe.contains('hybrid') || probe.contains('mixed')) {
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

String _courseSummaryLine(CourseModel course) {
  final desc = course.description?.trim();
  if (desc != null && desc.isNotEmpty) {
    final normalized = desc.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 54) return normalized;
    final slice = normalized.substring(0, 54);
    final breakAt = slice.lastIndexOf(RegExp(r'[\s،,.;]'));
    final cut = (breakAt > 24 ? slice.substring(0, breakAt) : slice).trim();
    return '$cut…';
  }
  if (course.institute.isNotEmpty) return course.institute;
  return course.categoryName?.trim() ?? '';
}

({Color bg, Color fg}) _levelBadgeColors(String level) {
  final l = level.toLowerCase();
  if (l.contains('مبتد') || l.contains('beginner')) {
    return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534));
  }
  if (l.contains('متوسط') || l.contains('intermediate')) {
    return (bg: AppColors.infoSoft, fg: AppColors.infoText);
  }
  if (l.contains('متقد') || l.contains('advanced')) {
    return (bg: AppColors.dangerSoft, fg: AppColors.dangerText);
  }
  return (bg: AppColors.neutralFill, fg: AppColors.textMuted);
}

String _courseActionLabel(CourseModel course) => course.isRegistrationOpen ? 'enroll_now'.tr : 'view_details'.tr;
