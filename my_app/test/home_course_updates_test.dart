import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/app_lifecycle_sync.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/routes/app_routes.dart';

import 'layout/fakes.dart';

/// الرئيسية لا تستبدل بطاقات الدورات إن جاءت بنفس المحتوى (لا وميض صور)، لكن «نفس المحتوى» كان يقارن
/// بعض الحقول فقط: تعديل السعة أو الخصم أو المستوى أو التمييز من لوحة التحكم لا يصل للبطاقات (ولا لتفاصيل
/// الدورة التي تبدأ منها) حتى إعادة فتح التطبيق، حتى بالسحب للتحديث. والعودة للتطبيق من الخلفية لم تكن
/// تحدّث الرئيسية الظاهرة أبداً.
Map<String, dynamic> _json({Map<String, dynamic> changes = const {}}) => {
  'id': 7,
  'title_ar': 'تصميم واجهات',
  'title_en': 'UI Design',
  'price': '200000',
  'level': 'beginner',
  'study_type': 'online',
  'max_students': 14,
  'current_students': 2,
  'start_date': '2026-11-20',
  'registration_deadline': '2026-11-15',
  'average_rating': '4.5',
  'reviews_count': 2,
  ...changes,
};

class _ServerCourses extends CourseRepository {
  _ServerCourses(ApiClient client) : super(client, Get.find<CourseRatingService>());
  Map<String, dynamic> json = _json();

  @override
  Future<List<CourseModel>> fetchCourses({Map<String, dynamic>? query}) async => [CourseModel.fromJson(json)];
  @override
  Future<List<CourseModel>> fetchSuggestedCourses({int limit = 10}) async => const [];
}

void main() {
  late _ServerCourses repo;
  late HomeController home;

  setUp(() async {
    final tokens = await registerFakes(loggedIn: false, locale: 'ar');
    repo = replaceFake<CourseRepository>(_ServerCourses(Get.find<ApiClient>())) as _ServerCourses;
    home = Get.put(HomeController(tokens));
    await home.loadHome(forceRefresh: true);
    expect(home.courses.single.maxStudents, 14);
  });
  tearDown(() {
    MemoryCache.clock = DateTime.now;
    FakeApi.reset();
    Get.reset();
  });

  final edits = <String, (Map<String, dynamic>, Object? Function(CourseModel))>{
    'capacity': ({'max_students': 20}, (c) => c.maxStudents),
    'discount': ({'discount_price': '150000'}, (c) => c.discountPrice),
    'level': ({'level': 'advanced'}, (c) => c.levelCode),
    'study mode': ({'study_type': 'in_person'}, (c) => c.studyTypeCode),
    'featured': ({'is_featured': 1}, (c) => c.isFeatured),
    'start date': ({'start_date': '2026-12-01'}, (c) => c.startDate),
    'registration deadline': ({'registration_deadline': '2026-11-30'}, (c) => c.registrationDeadline),
    'reviews count': ({'reviews_count': 3}, (c) => c.reviewsCount),
    'duration': ({'duration_hours': 40}, (c) => c.durationHours),
  };

  for (final MapEntry(key: name, value: (change, read)) in edits.entries) {
    test('a $name change from the dashboard reaches the home cards on refresh', () async {
      final before = read(home.courses.single);
      repo.json = _json(changes: change);
      await home.loadHome(forceRefresh: true);
      final after = read(home.courses.single);
      expect(after, isNot(before));
      expect(after, read(CourseModel.fromJson(repo.json)));
    });
  }

  test('the same data again keeps the same objects (no image flicker)', () async {
    final before = home.courses.single;
    await home.loadHome(forceRefresh: true);
    expect(identical(home.courses.single, before), isTrue);
  });

  group('back from the background', () {
    late DateTime now;

    Future<void> resume() async {
      Get.find<AppLifecycleSync>().didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    setUp(() async {
      now = DateTime(2026, 10, 28, 12);
      MemoryCache.clock = () => now;
      await home.loadHome(forceRefresh: true);
      Get.put(RootController()).currentIndex.value = 2;
      Get.put(AppLifecycleSync());
      Get.routing.current = AppRoutes.root;
      repo.json = _json(changes: {'max_students': 20});
    });

    test('after a while: the visible home is refreshed', () async {
      now = now.add(const Duration(minutes: 10));
      await resume();
      expect(home.courses.single.maxStudents, 20);
    });

    test('a moment later: nothing is refetched', () async {
      now = now.add(const Duration(seconds: 30));
      await resume();
      expect(home.courses.single.maxStudents, 14);
    });

    test('home not on screen (another page on top): left alone', () async {
      Get.routing.current = AppRoutes.courseDetails;
      now = now.add(const Duration(minutes: 10));
      await resume();
      expect(home.courses.single.maxStudents, 14);
    });
  });
}
