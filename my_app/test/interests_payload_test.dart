import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/register_payload.dart';
import 'package:my_app/core/models/student_profile_payload.dart';
import 'package:my_app/core/network/json_parser.dart';
import 'package:my_app/core/storage/academic_profile_cache.dart';

void main() {
  test('register sends interests only as preferred_categories', () {
    final json = RegisterPayload(
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.c',
      password: 'secret12',
      passwordConfirmation: 'secret12',
      cityId: 1,
      preferredCategories: [3, 5],
    ).toJson();

    expect(json['preferred_categories'], [3, 5]);
    expect(json['student_profile']['preferred_categories'], [3, 5]);
    expect(json.containsKey('preferred_tags'), isFalse);
    expect((json['student_profile'] as Map).containsKey('tag_ids'), isFalse);
  });

  test('profile update sends interests only as preferred_categories', () {
    final json = StudentProfilePayload(preferredCategories: [7]).toJson();

    expect(json['preferred_categories'], [7]);
    expect(json.containsKey('preferred_tags'), isFalse);
  });

  test('tag ids from the server or an old cache are not read as categories', () {
    expect(
      extractPreferredInterestIds({
        'preferred_tags': [1, 2],
      }),
      isEmpty,
    );
    expect(
      extractPreferredInterestIds({
        'preferred_categories': [4],
      }),
      [4],
    );
    expect(
      AcademicProfileCache.fromJson({
        'preferred_tags': [1, 2],
      }).preferredCategoryIds,
      isEmpty,
    );
  });
}
