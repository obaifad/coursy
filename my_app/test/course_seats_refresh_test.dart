import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';

import 'layout/fakes.dart';

/// بطاقة السعة في تفاصيل الدورة: ما يرسله الخادم من `/courses/{id}` هو المعتمد. كان التطبيق يُبقي الأكبر
/// بين عدد البطاقة (القائمة، وقد تكون محفوظة على الجهاز من فتح سابق) وعدد الخادم، فإلغاء حجز أو
/// تعديله من لوحة التحكم لا ينزل العدد أبداً — ولا حتى بالسحب للتحديث.
CourseModel _course({required int current, int max = 14}) => CourseModel.fromJson({
  'id': 3,
  'title_ar': 'تصميم واجهات الموبايل',
  'title_en': 'Mobile UI Design',
  'price': '100000',
  'max_students': max,
  'current_students': current,
});

class _ServerCourses extends CourseRepository {
  _ServerCourses(ApiClient client) : super(client, Get.find<CourseRatingService>());
  CourseModel server = _course(current: 2);

  @override
  Future<CourseModel> fetchCourseById(int id) async => server;
  @override
  Future<List<ScheduleModel>> fetchCourseSchedules(int courseId) async => const [];
}

void main() {
  late _ServerCourses repo;

  setUp(() async {
    await registerFakes(loggedIn: false, locale: 'ar');
    Get.put(MemoryCache());
    repo = replaceFake<CourseRepository>(_ServerCourses(Get.find<ApiClient>())) as _ServerCourses;
  });
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  CourseDetailsController open(CourseModel seed) {
    Get.routing.args = seed;
    return Get.put<CourseDetailsController>(CourseDetailsController());
  }

  test('fewer bookings on the server than on the (older) card: the server count is shown', () async {
    final c = open(_course(current: 5));
    await settle();
    expect(c.course.value!.enrolledCountForCapacity, 2);
  });

  test('pull to refresh picks up a booking cancelled from the dashboard', () async {
    repo.server = _course(current: 5);
    final c = open(_course(current: 5));
    await settle();
    expect(c.course.value!.enrolledCountForCapacity, 5);

    repo.server = _course(current: 3);
    await c.refreshDetails();
    expect(c.course.value!.enrolledCountForCapacity, 3);
  });

  test('a new capacity set from the dashboard is shown', () async {
    repo.server = _course(current: 2, max: 20);
    final c = open(_course(current: 2));
    await settle();
    expect(c.course.value!.maxStudents, 20);
  });

  test('the server sends no count: the card count stays', () async {
    repo.server = CourseModel.fromJson({'id': 3, 'title_ar': 'x', 'title_en': 'x', 'max_students': 14});
    final c = open(_course(current: 4));
    await settle();
    expect(c.course.value!.enrolledCountForCapacity, 4);
  });
}
