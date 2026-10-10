import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/utils/external_launcher.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/design_system.dart';
import '../upcoming_lecture.dart';

/// للطالب المسجّل بتسجيل مؤكد: ترحيب + أقرب محاضرة (الموعد، المعهد، رقم الجلسة) + تفاصيل الدورة والتواصل.
class UpcomingLectureCard extends StatelessWidget {
  const UpcomingLectureCard({super.key, required this.lecture, this.now});

  final UpcomingLecture lecture;

  /// للاختبار فقط؛ الافتراضي الوقت الحالي.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final course = lecture.course;
    final current = now ?? DateTime.now();
    final city = course.instituteCity?.trim() ?? '';
    final place = [course.institute.trim(), city].where((p) => p.isNotEmpty).join(' • ');
    final timeLine = [
      _timeRange(lecture.start, lecture.end),
      if (lecture.sessionNumber != null)
        'session_progress'.trParams({'n': '${lecture.sessionNumber}', 'total': '${lecture.totalSessions}'}),
    ].join(' · ');
    final contact = _InstituteContact.of(course);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'home_welcome_back'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.tajawal(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // أيقونة بدل الإيموجي: لا تعتمد على خط إيموجي في الجهاز (كانت تظهر مربعاً فارغاً).
                    const Icon(Icons.waving_hand_rounded, size: 20, color: AppColors.ratingStar),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _ConfirmedBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lecture.isOngoing(current) ? 'lecture_now'.tr : 'next_lecture'.tr,
            style: AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BidiText(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoLine(icon: Icons.apartment_rounded, text: place),
                    ],
                    const SizedBox(height: 4),
                    _InfoLine(icon: Icons.schedule_rounded, text: timeLine),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _DateTile(start: lecture.start, now: current),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CardButton.filled(
                  label: 'course_details'.tr,
                  onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
                ),
              ),
              if (contact != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _CardButton.soft(label: 'contact_institute'.tr, onTap: contact.open),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// واتساب المعهد، ثم الهاتف، ثم صفحة المعهد (فيها وسائل التواصل)؛ null = لا شيء متاح فيُخفى الزر.
class _InstituteContact {
  const _InstituteContact(this.open);

  final VoidCallback open;

  static _InstituteContact? of(CourseModel course) {
    final whatsapp = course.instituteWhatsapp?.trim() ?? '';
    if (whatsapp.isNotEmpty) return _InstituteContact(() => ExternalLauncher.openWhatsApp(whatsapp));
    final phone = course.institutePhone?.trim() ?? '';
    if (phone.isNotEmpty) return _InstituteContact(() => ExternalLauncher.openPhone(phone));
    final id = course.instituteId;
    if (id != null) return _InstituteContact(() => Get.toNamed(AppRoutes.instituteDetails, arguments: id));
    return null;
  }
}

class _ConfirmedBadge extends StatelessWidget {
  const _ConfirmedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              'enrollment_confirmed_badge'.tr,
              style: AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.successText),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 5),
        Expanded(
          child: BidiText(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// مربع بنفسجي: اليوم (اليوم / غداً / اسم اليوم)، الساعة، والفترة.
class _DateTile extends StatelessWidget {
  const _DateTile({required this.start, required this.now});

  final DateTime start;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start.year, start.month, start.day);
    final diff = day.difference(today).inDays;
    final dayLabel = diff == 0
        ? 'today'.tr
        : diff == 1
        ? 'tomorrow'.tr
        : JsonHelpers.weekdayLabel(_weekdayName(start.weekday));
    final (time, period) = _clock(start, long: true);

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fit(dayLabel, AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          _fit(time, AppFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          _fit(period, AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _fit(String text, TextStyle style) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, style: style),
  );
}

/// زر بعرض كامل داخل البطاقة: ممتلئ (بنفسجي) أو ناعم (خلفية بنفسجية فاتحة).
class _CardButton extends StatelessWidget {
  const _CardButton.filled({required this.label, required this.onTap}) : soft = false;

  const _CardButton.soft({required this.label, required this.onTap}) : soft = true;

  final String label;
  final VoidCallback onTap;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final style = soft
        ? FilledButton.styleFrom(backgroundColor: AppColors.surfaceVariant, foregroundColor: AppColors.primary)
        : FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white);
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onTap,
        style: style.copyWith(
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          textStyle: WidgetStatePropertyAll(AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
      ),
    );
  }
}

/// للزائر غير المسجّل: دعوة لإنشاء حساب أو تصفّح الدورات.
class GuestSignUpBanner extends StatelessWidget {
  const GuestSignUpBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: AppColors.shadowPrimary, blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'guest_banner_title'.tr,
                      style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'guest_banner_subtitle'.tr,
                      style: AppFonts.tajawal(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.event_seat_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text('register'.tr, maxLines: 1)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => AppNavigation.switchToTab(0),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.75)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text('browse_courses_short'.tr, maxLines: 1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _weekdayName(int weekday) => const {
  DateTime.monday: 'monday',
  DateTime.tuesday: 'tuesday',
  DateTime.wednesday: 'wednesday',
  DateTime.thursday: 'thursday',
  DateTime.friday: 'friday',
  DateTime.saturday: 'saturday',
  DateTime.sunday: 'sunday',
}[weekday]!;

/// «5:00» والفترة («مساءً» / «م» / «PM»).
(String, String) _clock(DateTime t, {required bool long}) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final time = '$h12:${t.minute.toString().padLeft(2, '0')}';
  final pm = t.hour >= 12;
  final key = long ? (pm ? 'time_pm_long' : 'time_am_long') : (pm ? 'time_pm' : 'time_am');
  return (time, key.tr);
}

/// «5:00 - 7:00 م»، أو «11:00 ص - 1:00 م» حين تختلف الفترة.
String _timeRange(DateTime start, DateTime end) {
  final (s, sp) = _clock(start, long: false);
  final (e, ep) = _clock(end, long: false);
  return sp == ep ? '$s - $e $ep' : '$s $sp - $e $ep';
}
