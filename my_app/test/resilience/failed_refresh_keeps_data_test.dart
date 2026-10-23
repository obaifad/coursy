import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/instructors/controllers/instructor_details_controller.dart';
import 'package:my_app/modules/instructors/controllers/instructor_subject_instructors_controller.dart';
import 'package:my_app/modules/instructors/controllers/private_instructors_controller.dart';

import '../layout/fakes.dart';
import '../layout/sample_data.dart';

/// تحديث فاشل (سحب، عودة، تغيير لغة) والبيانات ظاهرة: تبقى البيانات كما هي، بلا رسالة خطأ مكانها.
void main() {
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> settle(WidgetTester tester) => tester.pump(const Duration(seconds: 1));

  testWidgets('institute details: failed refresh keeps courses and instructors', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.routing.args = sampleInstitutes().first;
    final c = Get.put(InstituteDetailsController(), tag: 'i');
    await settle(tester);
    expect(c.courses, isNotEmpty);
    expect(c.instructors, isNotEmpty);

    FakeApi.failing.add('*');
    await c.loadDetails();
    expect(c.courses, isNotEmpty, reason: 'courses wiped by a failed refresh');
    expect(c.instructors, isNotEmpty, reason: 'instructors wiped by a failed refresh');
    expect(c.coursesError.value, isNull);
    expect(c.instructorsError.value, isNull);
  });

  testWidgets('instructor details: failed refresh keeps reviews', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.routing.args = sampleInstructors().first;
    final c = Get.put(InstructorDetailsController(), tag: 'r');
    await settle(tester);
    expect(c.reviews, isNotEmpty);

    FakeApi.failing.add('fetchReviews');
    await c.loadDetails();
    expect(c.reviews, isNotEmpty, reason: 'reviews wiped -> "no reviews" instead of the shown reviews');
    expect(c.reviewsError.value, isNull);
  });

  testWidgets('instructor details: no data + failure -> error with retry, then recovery', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final target = sampleInstructors()[1];
    Get.routing.args = target.id; // من إشعار: المعرّف فقط
    FakeApi.failing.addAll(['fetchInstructorById', 'fetchReviews']);
    final c = Get.put(InstructorDetailsController(), tag: 'e');
    await settle(tester);
    expect(c.instructor.value, isNull);
    expect(c.isLoading.value, isFalse, reason: 'no endless loading');
    expect(c.detailsError.value, isNotNull, reason: 'blank page instead of an error with retry');
    expect(c.reviewsError.value, isNotNull, reason: '"no reviews" instead of an error with retry');

    FakeApi.failing.clear();
    await c.loadDetails();
    expect(c.instructor.value?.id, target.id);
    expect(c.detailsError.value, isNull);
    expect(c.reviews, isNotEmpty);
  });

  testWidgets('private instructors: failed refresh keeps the list and the subject filters', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final c = Get.put(PrivateInstructorsController(Get.find()));
    await settle(tester);
    expect(c.instructors, isNotEmpty);
    expect(c.subjects, isNotEmpty);

    FakeApi.failing.add('*');
    await c.reloadLocalizedData();
    expect(c.instructors, isNotEmpty, reason: 'list replaced by an error');
    expect(c.subjects, isNotEmpty, reason: 'filters wiped');
    expect(c.errorMessage.value, isNull);
  });

  testWidgets('subject instructors: failed refresh keeps the list', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.routing.args = {'key': 'spec:1', 'name': 'رياضيات'};
    final c = Get.put(InstructorSubjectInstructorsController());
    await settle(tester);
    expect(c.instructors, isNotEmpty);

    FakeApi.failing.add('*');
    await c.loadInstructors();
    expect(c.instructors, isNotEmpty);
    expect(c.errorMessage.value, isNull);
  });

  testWidgets('favorites: a course that fails to refresh keeps its previous data', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _FailOneCourse(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    replaceFake<CourseRepository>(repo);
    final c = Get.put(FavoritesController());
    c.onPageOpened(); // الصفحة تفتح المتحكّم الدائم، وهو لا يحمّل وحده عند إنشائه.
    await settle(tester);
    final before = c.courses.map((e) => e.id).toList();
    expect(before, [1, 4]);

    // الدورة 4 تفشل في التحديث، الدورة 1 تنجح.
    repo.failId = 4;
    await c.loadFavorites();
    expect(c.courses.map((e) => e.id).toList(), before, reason: 'course 4 disappeared from favorites');
  });
}

class _FailOneCourse extends CourseRepository {
  _FailOneCourse(super.client, super.rating);

  int? failId;

  @override
  Future<CourseModel> fetchCourseById(int id) async {
    if (id == failId) throw ApiException('offline', statusCode: 503);
    return sampleCourses().firstWhere((c) => c.id == id);
  }
}
