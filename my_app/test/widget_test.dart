import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/json_helpers.dart';
import 'package:my_app/core/network/api_endpoints.dart';
import 'package:my_app/core/network/json_parser.dart';

void main() {
  test('API base endpoints', () {
    expect(ApiEndpoints.courses, '/courses');
    expect(ApiEndpoints.institutes, '/institutes');
    expect(ApiEndpoints.studentLogin, '/student/login');
  });

  test('parses Laravel paginated courses list', () {
    final body = {
      'current_page': 1,
      'data': [
        {
          'id': 3,
          'title': 'Business English',
          'institute_id': 2,
          'price': '300000.00',
          'discount_price': '270000.00',
          'level': 'intermediate',
          'study_type': 'online',
          'duration_hours': 36,
          'current_students': 10,
          'average_rating': '3.75',
          'institute': {'id': 2, 'name': 'Skills Academy', 'average_rating': '4.40'},
        },
      ],
      'total': 1,
    };
    final list = extractListMap(body);
    expect(list.length, 1);
    final course = CourseModel.fromJson(list.first);
    expect(course.title, 'Business English');
    expect(course.institute, 'Skills Academy');
    expect(course.price, contains('270000'));
    expect(course.level, 'متوسط');
    expect(course.studyType, 'أونلاين');
    expect(course.rating, 3.75);
  });

  test('course rating falls back to institute average', () {
    final course = CourseModel.fromJson({
      'id': 1,
      'title': 'Test',
      'institute': {'id': 2, 'name': 'Academy', 'average_rating': '4.2'},
    });
    expect(course.rating, 4.2);
  });

  test('course rating from embedded reviews', () {
    final rating = JsonHelpers.resolveCourseRating({
      'reviews': [
        {'rating': 4},
        {'rating': 5},
      ],
    });
    expect(rating, 4.5);
  });

  test('parses Laravel paginated cities list', () {
    final body = {
      'current_page': 1,
      'data': [
        {'id': 4, 'name': 'Latakia'},
        {'id': 1, 'name': 'Damascus'},
      ],
      'total': 2,
    };
    final list = extractListMap(body);
    expect(list.length, 2);
    final city = CityModel.fromJson(list.first);
    expect(city.name, 'Latakia');
    expect(city.id, 4);
  });

  test('parses notification with is_read 0', () {
    final n = NotificationModel.fromJson({
      'id': 3,
      'title': 'Class reminder',
      'body': 'Starts next week',
      'type': 'reminder',
      'is_read': 0,
    });
    expect(n.isRead, isFalse);
    expect(n.type, 'reminder');
  });
}
