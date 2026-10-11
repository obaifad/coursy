import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/navigation/route_scoped_tag.dart';

void main() {
  group('RouteScopedTag', () {
    test('each opened detail page gets its own controller tag', () {
      final first = RouteScopedTag.reserve('course');
      expect(RouteScopedTag.take(), first);

      final second = RouteScopedTag.reserve('course');
      expect(second, isNot(first));
      expect(RouteScopedTag.take(), second);
    });

    test('take without a new reserve returns the last tag', () {
      final tag = RouteScopedTag.reserve('institute');
      RouteScopedTag.take();
      expect(RouteScopedTag.take(), tag);
    });
  });

  group('course rating', () {
    test('a course nobody reviewed has no rating, even if its institute has one', () {
      final course = CourseModel.fromJson({
        'id': 1,
        'title': 'Python',
        'average_rating': '0.00',
        'reviews_count': 0,
        'institute': {'id': 3, 'name': 'Masar', 'average_rating': '4.70'},
      });
      expect(course.rating, 0);
      expect(course.hasRating, isFalse);
    });

    test('a reviewed course shows its own rating', () {
      final course = CourseModel.fromJson({
        'id': 1,
        'title': 'Python',
        'average_rating': '3.50',
        'reviews_count': 2,
        'institute': {'id': 3, 'name': 'Masar', 'average_rating': '4.70'},
      });
      expect(course.rating, 3.5);
      expect(course.reviewsCount, 2);
      expect(course.hasRating, isTrue);
    });

    test('an older server without reviews_count still falls back to the institute rating', () {
      final course = CourseModel.fromJson({
        'id': 1,
        'title': 'Python',
        'institute': {'id': 3, 'name': 'Masar', 'average_rating': '4.70'},
      });
      expect(course.rating, 4.7);
    });
  });

  group('online courses', () {
    test('study type online is detected from the raw code', () {
      expect(CourseModel.fromJson({'id': 1, 'title': 'x', 'study_type': 'online'}).isOnline, isTrue);
      expect(CourseModel.fromJson({'id': 1, 'title': 'x', 'study_type': 'hybrid'}).isOnline, isFalse);
      expect(CourseModel.fromJson({'id': 1, 'title': 'x'}).isOnline, isFalse);
    });

    test('the payment screen knows an online course is paid to the institute directly', () {
      final info = ShamCashInfo.fromJson({'available': false, 'reason': 'online_course'});
      expect(info.canPay, isFalse);
      expect(info.isOnlineCourse, isTrue);
      expect(ShamCashInfo.fromJson({'available': false}).isOnlineCourse, isFalse);
    });
  });
}
