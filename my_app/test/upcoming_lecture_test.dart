import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/modules/home/upcoming_lecture.dart';
import 'package:my_app/modules/home/widgets/home_status_banner.dart';

// الثلاثاء 13 أكتوبر 2026، الساعة 3 عصراً.
final _now = DateTime(2026, 10, 13, 15);

CourseModel _course({
  int id = 1,
  String? start = '2026-09-22',
  String? end,
  int? sessions = 12,
  String? whatsapp,
  List<ScheduleModel> schedules = const [],
}) {
  return CourseModel.fromJson({
    'id': id,
    'title_ar': 'بايثون للمبتدئين',
    'title_en': 'Python for Beginners',
    'start_date': start,
    'end_date': end,
    'sessions_count': sessions,
    'institute': {
      'id': 5,
      'name_ar': 'معهد المسار للتدريب',
      'name_en': 'Al-Masar Institute',
      'whatsapp': whatsapp,
      'city': {'id': 1, 'name_ar': 'دمشق', 'name_en': 'Damascus'},
    },
  }).copyWith(schedules: schedules);
}

ScheduleModel _slot(String day, String from, String to) =>
    ScheduleModel(id: 1, dayOfWeek: day, startTime: from, endTime: to);

EnrollmentModel _enrollment(CourseModel course, {String status = 'approved', int id = 1}) =>
    EnrollmentModel(id: id, status: status, paymentStatus: 'paid', courseId: course.id, course: course);

UpcomingLecture? _find(List<EnrollmentModel> list, {DateTime? now}) =>
    UpcomingLecture.find(list, (e) => e.course!.schedules, now ?? _now);

void main() {
  test('next lecture today with session number from the start date', () {
    final course = _course(schedules: [_slot('tuesday', '17:00', '19:00')]);
    final lecture = _find([_enrollment(course)])!;

    expect(lecture.start, DateTime(2026, 10, 13, 17));
    expect(lecture.end, DateTime(2026, 10, 13, 19));
    // الثلاثاء: 22/9، 29/9، 6/10، 13/10 → الجلسة 4 من 12.
    expect(lecture.sessionNumber, 4);
    expect(lecture.totalSessions, 12);
    expect(lecture.isOngoing(_now), isFalse);
  });

  test('a lecture in progress is still the current one', () {
    final course = _course(schedules: [_slot('tuesday', '14:00', '16:00')]);
    final lecture = _find([_enrollment(course)])!;

    expect(lecture.start, DateTime(2026, 10, 13, 14));
    expect(lecture.isOngoing(_now), isTrue);
  });

  test('after today\'s lecture ends, the next week\'s one is picked', () {
    final course = _course(schedules: [_slot('tuesday', '10:00', '12:00')]);
    expect(_find([_enrollment(course)])!.start, DateTime(2026, 10, 20, 10));
  });

  test('pending, rejected and finished courses are ignored', () {
    final slots = [_slot('wednesday', '10:00', '12:00')];
    expect(_find([_enrollment(_course(schedules: slots), status: 'pending')]), isNull);
    expect(_find([_enrollment(_course(schedules: slots), status: 'rejected')]), isNull);
    expect(_find([_enrollment(_course(end: '2026-10-01', schedules: slots))]), isNull);
    expect(_find([_enrollment(_course())]), isNull, reason: 'no schedule known');
  });

  test('earliest lecture across several courses wins', () {
    final later = _course(id: 1, schedules: [_slot('thursday', '10:00', '12:00')]);
    final sooner = _course(id: 2, schedules: [_slot('wednesday', '18:00', '20:00')]);
    final lecture = _find([_enrollment(later, id: 1), _enrollment(sooner, id: 2)])!;
    expect(lecture.course.id, 2);
  });

  test('a course starting later begins from its start date, with no progress before it', () {
    final course = _course(start: '2026-11-03', schedules: [_slot('tuesday', '17:00', '19:00')]);
    final lecture = _find([_enrollment(course)])!;
    expect(lecture.start, DateTime(2026, 11, 3, 17));
    expect(lecture.sessionNumber, 1);
  });

  test('numeric (Carbon) and Arabic weekday names', () {
    expect(
      _find([
        _enrollment(_course(schedules: [_slot('2', '17:00', '19:00')])),
      ])!.start.weekday,
      DateTime.tuesday,
    );
    expect(
      _find([
        _enrollment(_course(schedules: [_slot('0', '17:00', '19:00')])),
      ])!.start.weekday,
      DateTime.sunday,
    );
    expect(
      _find([
        _enrollment(_course(schedules: [_slot('الخميس', '17:00', '19:00')])),
      ])!.start.weekday,
      DateTime.thursday,
    );
  });

  testWidgets('lecture card shows the session line, time tile and both actions', (tester) async {
    final course = _course(whatsapp: '0933000000', schedules: [_slot('tuesday', '17:00', '19:00')]);
    final lecture = _find([_enrollment(course)])!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: UpcomingLectureCard(lecture: lecture, now: _now),
          ),
        ),
      ),
    );

    // الترجمات غير محمّلة في هذا الاختبار فتظهر المفاتيح.
    expect(find.text('5:00'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(find.textContaining('5:00 - 7:00'), findsOneWidget);
    expect(find.text('course_details'), findsOneWidget);
    expect(find.text('contact_institute'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
