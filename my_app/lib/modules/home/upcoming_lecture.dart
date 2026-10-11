import '../../core/models/app_models.dart';
import '../../core/models/json_helpers.dart';

/// أقرب محاضرة قادمة (أو جارية الآن) للطالب، محسوبة من جدول الدورة الأسبوعي على الجهاز.
class UpcomingLecture {
  const UpcomingLecture({
    required this.enrollment,
    required this.course,
    required this.start,
    required this.end,
    this.sessionNumber,
    this.totalSessions,
  });

  final EnrollmentModel enrollment;
  final CourseModel course;
  final DateTime start;
  final DateTime end;

  /// رقم هذه الجلسة من بداية الدورة، و[totalSessions] عددها الكلي — null إن لم يُعرف تاريخ البدء/العدد.
  final int? sessionNumber;
  final int? totalSessions;

  bool isOngoing(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  /// يبحث في التسجيلات المؤكّدة فقط. [schedulesFor] جدول كل دورة (من الدورة نفسها أو من `/course-schedules`).
  static UpcomingLecture? find(
    List<EnrollmentModel> enrollments,
    List<ScheduleModel> Function(EnrollmentModel enrollment) schedulesFor,
    DateTime now,
  ) {
    UpcomingLecture? best;
    for (final enrollment in enrollments) {
      if (!isConfirmed(enrollment.status)) continue;
      final course = enrollment.course;
      if (course == null) continue;
      final slots = schedulesFor(enrollment).map(_Slot.parse).whereType<_Slot>().toList();
      if (slots.isEmpty) continue;

      final next = _nextOccurrence(slots, course, now);
      if (next == null) continue;
      if (best == null || next.start.isBefore(best.start)) {
        final (number, total) = _progress(slots, course, next.start);
        best = UpcomingLecture(
          enrollment: enrollment,
          course: course,
          start: next.start,
          end: next.end,
          sessionNumber: number,
          totalSessions: total,
        );
      }
    }
    return best;
  }

  static bool isConfirmed(String status) {
    final s = status.toLowerCase();
    return s == 'approved' || s == 'confirmed';
  }

  static ({DateTime start, DateTime end})? _nextOccurrence(List<_Slot> slots, CourseModel course, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = JsonHelpers.tryParseDateOnly(course.startDate);
    final lastDay = JsonHelpers.tryParseDateOnly(course.endDate);
    if (lastDay != null && lastDay.isBefore(today)) return null;

    ({DateTime start, DateTime end})? best;
    // أسبوعان: يكفي لإيجاد الموعد التالي حتى لو بدأت الدورة بعد أيام.
    for (var d = 0; d < 14; d++) {
      final day = DateTime(today.year, today.month, today.day + d);
      if (firstDay != null && day.isBefore(firstDay)) continue;
      if (lastDay != null && day.isAfter(lastDay)) break;
      for (final slot in slots) {
        if (slot.weekday != day.weekday) continue;
        final start = slot.startOn(day);
        final end = slot.endOn(day);
        if (!end.isAfter(now)) continue;
        if (best == null || start.isBefore(best.start)) best = (start: start, end: end);
      }
      if (best != null) return best;
    }
    // بداية الدورة بعد أكثر من أسبوعين: أول موعد بعد تاريخ البدء.
    if (firstDay != null && firstDay.isAfter(today)) {
      for (var d = 0; d < 7; d++) {
        final day = DateTime(firstDay.year, firstDay.month, firstDay.day + d);
        for (final slot in slots) {
          if (slot.weekday != day.weekday) continue;
          final start = slot.startOn(day);
          if (best == null || start.isBefore(best.start)) best = (start: start, end: slot.endOn(day));
        }
        if (best != null) return best;
      }
    }
    return null;
  }

  /// (رقم الجلسة، العدد الكلي). العدد من `sessions_count` أو بعدّ المواعيد حتى تاريخ النهاية.
  static (int?, int?) _progress(List<_Slot> slots, CourseModel course, DateTime occurrence) {
    final firstDay = JsonHelpers.tryParseDateOnly(course.startDate);
    if (firstDay == null) return (null, null);
    final lastDay = JsonHelpers.tryParseDateOnly(course.endDate);

    int countUntil(DateTime limit) {
      var count = 0;
      for (var d = 0; d < 400; d++) {
        final day = DateTime(firstDay.year, firstDay.month, firstDay.day + d);
        if (day.isAfter(limit)) break;
        for (final slot in slots) {
          if (slot.weekday == day.weekday && !slot.startOn(day).isAfter(limit)) count++;
        }
      }
      return count;
    }

    final number = countUntil(occurrence);
    final declared = course.sessionsCount;
    final total = declared != null && declared > 0
        ? declared
        : (lastDay != null ? countUntil(DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59)) : null);
    if (number <= 0 || total == null || number > total) return (null, null);
    return (number, total);
  }
}

/// موعد أسبوعي: يوم (DateTime.weekday) + ساعة البدء والنهاية.
class _Slot {
  const _Slot(this.weekday, this.startMinutes, this.endMinutes);

  final int weekday;
  final int startMinutes;
  final int endMinutes;

  DateTime startOn(DateTime day) => DateTime(day.year, day.month, day.day, 0, startMinutes);

  DateTime endOn(DateTime day) => DateTime(day.year, day.month, day.day, 0, endMinutes);

  static _Slot? parse(ScheduleModel schedule) {
    final weekday = _weekday(schedule.dayOfWeek);
    final start = _minutes(schedule.startTime);
    final end = _minutes(schedule.endTime);
    if (weekday == null || start == null) return null;
    return _Slot(weekday, start, end != null && end > start ? end : start + 60);
  }

  static int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// أسماء إنجليزية أو عربية، أو رقم (Carbon: 0 = الأحد … 6 = السبت؛ و7 = الأحد أيضاً).
  static int? _weekday(String raw) {
    final v = raw.trim().toLowerCase();
    const names = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
      'الاثنين': DateTime.monday,
      'الإثنين': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الاربعاء': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'السبت': DateTime.saturday,
      'الأحد': DateTime.sunday,
      'الاحد': DateTime.sunday,
    };
    final named =
        names[v] ?? names[v.length >= 3 ? names.keys.firstWhere((k) => k.startsWith(v), orElse: () => '') : ''];
    if (named != null) return named;
    final n = int.tryParse(v);
    if (n == null || n < 0 || n > 7) return null;
    return n == 0 ? DateTime.sunday : n;
  }
}
