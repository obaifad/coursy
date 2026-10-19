import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/city_repository.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/data/repositories/notification_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/institutes/controllers/city_details_controller.dart';
import 'package:my_app/modules/notifications/controllers/notifications_controller.dart';

import '../layout/fakes.dart';

/// بعد «المزيد» ثم تحديث فاشل، «المزيد» التالي يطلب الصفحة التالية فعلاً — لا يعيد صفحة معروضة
/// (كان عدّاد الصفحات يُصفَّر قبل الطلب فتتكرر العناصر).
class _Pages<T> {
  _Pages(this.make);

  final T Function(int page, int index) make;
  final requested = <int>[];
  bool failing = false;

  PaginatedResult<T> page(int page) {
    requested.add(page);
    if (failing) throw ApiException('offline', statusCode: 503);
    return PaginatedResult<T>(
      items: [for (var i = 0; i < 2; i++) make(page, i)],
      currentPage: page,
      lastPage: 5,
      total: 10,
      hasMore: page < 5,
    );
  }
}

class _CategoryPages extends CourseRepository {
  _CategoryPages(super.client, super.rating, this.pages);
  final _Pages<CourseModel> pages;
  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async => pages.page(page);
}

class _CityPages extends CityRepository {
  _CityPages(super.client, this.pages);
  final _Pages<InstituteModel> pages;
  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesByCity(int cityId, {int page = 1, int perPage = 15}) async =>
      pages.page(page);
  @override
  Future<CityModel> fetchCityById(int id) async => CityModel.fromJson({'id': id, 'name_ar': 'دمشق'});
}

class _NotificationPages extends NotificationRepository {
  _NotificationPages(super.client, this.pages);
  final _Pages<NotificationModel> pages;
  @override
  Future<PaginatedResult<NotificationModel>> fetchNotificationsPage({int page = 1, int perPage = 15}) async =>
      pages.page(page);
}

CourseModel _course(int page, int i) => CourseModel.fromJson({
  'id': page * 10 + i,
  'title_ar': 'دورة $page-$i',
  'title_en': 'Course $page-$i',
  'price': '1000',
});

void main() {
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> check<T>(
    WidgetTester tester, {
    required _Pages<T> pages,
    required List<Object> Function() ids,
    required Future<void> Function() loadMore,
    required Future<void> Function() refresh,
  }) async {
    await tester.pump(const Duration(seconds: 1));
    await loadMore(); // الصفحة 2
    expect(pages.requested, [1, 2]);

    pages.failing = true;
    await refresh(); // تحديث فاشل: القائمة (صفحتان) تبقى
    pages.failing = false;
    await loadMore();

    expect(pages.requested.last, 3, reason: 'load more after a failed refresh asked for page ${pages.requested.last}');
    expect(ids().toSet().length, ids().length, reason: 'duplicate items: ${ids()}');
  }

  testWidgets('category courses', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final pages = _Pages<CourseModel>(_course);
    replaceFake<CourseRepository>(_CategoryPages(Get.find<ApiClient>(), Get.find<CourseRatingService>(), pages));
    Get.routing.args = {'id': 3, 'name': 'البرمجة'};
    final c = Get.put(CategoryCoursesController());
    await check(
      tester,
      pages: pages,
      ids: () => c.courses.map((e) => e.id).toList(),
      loadMore: c.loadMore,
      refresh: c.loadCourses,
    );
  });

  testWidgets('city institutes', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final pages = _Pages<InstituteModel>(
      (page, i) => InstituteModel.fromJson({'id': page * 10 + i, 'name_ar': 'معهد $page-$i'}),
    );
    replaceFake<CityRepository>(_CityPages(Get.find<ApiClient>(), pages));
    Get.routing.args = {'id': 1, 'name': 'دمشق'};
    final c = Get.put(CityDetailsController());
    await check(
      tester,
      pages: pages,
      ids: () => c.institutes.map((e) => e.id).toList(),
      loadMore: c.loadMore,
      refresh: c.load,
    );
  });

  testWidgets('notifications', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final pages = _Pages<NotificationModel>(
      (page, i) => NotificationModel.fromJson({'id': page * 10 + i, 'title': 'إشعار $page-$i', 'type': 'info'}),
    );
    replaceFake<NotificationRepository>(_NotificationPages(Get.find<ApiClient>(), pages));
    final c = Get.put(NotificationsController());
    await check(
      tester,
      pages: pages,
      ids: () => c.items.map((e) => e.id).toList(),
      loadMore: c.loadMoreNotifications,
      refresh: c.loadNotifications,
    );
  });
}
