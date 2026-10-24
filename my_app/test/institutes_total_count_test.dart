import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/city_repository.dart';
import 'package:my_app/core/data/repositories/institute_repository.dart';
import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/modules/institutes/controllers/city_details_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// شارة «N معهد» تعرض العدد الكلي من الخادم (`total`)، لا عدد ما حُمّل من صفحات (كانت 12 والكلي 60).
PaginatedResult<InstituteModel> _pageOf(int page, {required int total, int perPage = 12}) {
  final base = sampleInstitutes().first;
  final count = (total - (page - 1) * perPage).clamp(0, perPage);
  return PaginatedResult<InstituteModel>(
    items: [
      for (var i = 0; i < count; i++)
        InstituteModel.fromJson({'id': page * 100 + i, 'name_ar': '${base.name} $page-$i', 'name_en': 'I $page-$i'}),
    ],
    currentPage: page,
    lastPage: (total / perPage).ceil(),
    total: total,
    hasMore: page * perPage < total,
  );
}

class _Paged extends InstituteRepository {
  _Paged(super.client);

  /// العدد الكلي بحسب المدينة (null = كل المدن).
  final totals = <int?, int>{null: 60, 1: 20};

  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async => _pageOf(page, total: totals[query?['city_id'] as int?] ?? 0, perPage: perPage);
}

class _PagedCity extends CityRepository {
  _PagedCity(super.client);
  @override
  Future<CityModel> fetchCityById(int id) async =>
      CityModel.fromJson({'id': id, 'name_ar': 'دمشق', 'name_en': 'Damascus'});
  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesByCity(int cityId, {int page = 1, int perPage = 15}) async =>
      _pageOf(page, total: 35, perPage: perPage);
}

void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  Future<InstitutesController> setUpTab() async {
    await registerFakes(loggedIn: true, locale: 'ar');
    replaceFake<InstituteRepository>(_Paged(Get.find<ApiClient>()));
    // النوع صريحاً: داخل دالة async يُستنتج FutureOr<InstitutesController> فيُسجَّل بنوع لا تجده الصفحة.
    return Get.put<InstitutesController>(InstitutesController());
  }

  test('the count is the server total, not the loaded page, and survives load-more', () async {
    final c = await setUpTab();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.institutes.length, 12);
    expect(c.displayCount, 60);

    await c.loadMoreInstitutes();
    expect(c.institutes.length, 24);
    expect(c.displayCount, 60);
  });

  test('changing the city updates the total', () async {
    final c = await setUpTab();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    c.selectCity(1);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.displayCount, 20);
  });

  test('without a server total the badge falls back to what is loaded', () async {
    final c = await setUpTab();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    c.totalCount.value = 0;
    expect(c.displayCount, c.institutes.length);
  });

  testWidgets('the header badge shows the total', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await setUpTab();
    await tester.pumpWidget(auditApp(child: const InstitutesView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(pluralTr('city_institutes_count', 60)), findsOneWidget);
    expect(find.text(pluralTr('city_institutes_count', 12)), findsNothing);
  });

  test('city page: the list total is used when the city has no institutes count', () async {
    await registerFakes(loggedIn: true, locale: 'ar');
    replaceFake<CityRepository>(_PagedCity(Get.find<ApiClient>()));
    Get.routing.args = <String, dynamic>{'id': 1, 'name': 'دمشق'};
    final c = Get.put(CityDetailsController());
    await c.load();
    expect(c.institutes.length, 12);
    expect(c.totalInstitutes.value, 35);
  });
}
