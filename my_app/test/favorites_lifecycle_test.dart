import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/favorites/views/favorites_view.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// المفضلة: المتحكّم يعيش طوال الجلسة، فالعودة للصفحة تعرض القائمة فوراً بلا هيكل ولا إعادة تنزيل؛
/// تجديد صامت بعد انتهاء الصلاحية؛ والسحب للتحديث يجلب من جديد دائماً.
void main() {
  setUpAll(loadAuditFonts);

  late DateTime now;

  Future<FavoritesController> open() async {
    await registerFakes(loggedIn: true, locale: 'ar');
    now = DateTime(2026, 10, 23, 12);
    FavoritesController.clock = () => now;
    FavoritesController.ensureRegistered();
    return Get.find<FavoritesController>();
  }

  tearDown(() {
    FavoritesController.clock = DateTime.now;
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

  int courseFetches() => FakeApi.count('fetchCourseById');

  test('the controller is permanent: it survives its page being removed', () async {
    final c = await open();
    expect(await Get.delete<FavoritesController>(), isFalse, reason: 'permanent instances are not deleted by routes');
    expect(Get.find<FavoritesController>(), same(c));
  });

  test('first open: skeleton state, then every favourite course is fetched once', () async {
    final c = await open();
    expect(c.isLoading.value, isTrue);
    c.onPageOpened();
    await settle();
    expect(c.courses.map((e) => e.id), [1, 4]);
    expect(c.isLoading.value, isFalse);
    expect(courseFetches(), 2);
  });

  test('coming back while fresh: nothing is requested and the list is already there', () async {
    final c = await open();
    c.onPageOpened();
    await settle();
    FakeApi.calls.clear();

    now = now.add(const Duration(seconds: 90));
    var sawSkeleton = false;
    c.isLoading.listen((v) => sawSkeleton = sawSkeleton || v);
    c.onPageOpened();
    expect(c.courses, hasLength(2), reason: 'shown at once');
    expect(c.isLoading.value, isFalse);
    await settle();
    expect(FakeApi.calls, isEmpty, reason: 'no request at all');
    expect(sawSkeleton, isFalse);
  });

  test('stale list, fresh details: only the list is synced, no course is downloaded again', () async {
    final c = await open();
    c.onPageOpened();
    await settle();
    FakeApi.calls.clear();

    now = now.add(const Duration(minutes: 3));
    c.onPageOpened();
    await settle();
    expect(courseFetches(), 0, reason: 'no full re-download on every entry');
    expect(c.courses, hasLength(2));
    expect(c.isLoading.value, isFalse);
  });

  test('stale details: refreshed silently, the list stays on screen while it runs', () async {
    final c = await open();
    c.onPageOpened();
    await settle();
    FakeApi.calls.clear();

    now = now.add(const Duration(minutes: 6));
    var sawSkeleton = false;
    c.isLoading.listen((v) => sawSkeleton = sawSkeleton || v);
    FakeApi.gate = Completer<void>(); // يوقف الردود: نفحص الحالة أثناء التجديد
    c.onPageOpened();
    await settle();
    expect(courseFetches(), greaterThan(0), reason: 'the refresh is in flight');
    expect(c.courses, hasLength(2), reason: 'the list stays while refreshing');
    expect(c.isLoading.value, isFalse);

    FakeApi.gate!.complete();
    await settle();
    expect(courseFetches(), 2, reason: 'details renewed once their 5 minutes are up');
    expect(c.courses, hasLength(2));
    expect(sawSkeleton, isFalse);
  });

  test('a failed silent refresh keeps what is on screen', () async {
    final c = await open();
    c.onPageOpened();
    await settle();

    now = now.add(const Duration(minutes: 6));
    FakeApi.failing.add('*');
    c.onPageOpened();
    await settle();
    expect(c.courses.map((e) => e.id), [1, 4]);
    expect(c.errorMessage.value, isNull);
  });

  test('pull to refresh always fetches again, without the skeleton', () async {
    final c = await open();
    c.onPageOpened();
    await settle();
    FakeApi.calls.clear();

    var sawSkeleton = false;
    c.isLoading.listen((v) => sawSkeleton = sawSkeleton || v);
    await c.loadFavorites();
    expect(FakeApi.count('fetchFavorites'), 1, reason: 'the list is forced');
    expect(courseFetches(), 2);
    expect(sawSkeleton, isFalse);
  });

  test('opening twice in a row (init + view) starts one load', () async {
    final c = await open();
    c.onPageOpened();
    c.onPageOpened();
    await settle();
    expect(courseFetches(), 2);
  });

  test('after logout the next open is a full load again', () async {
    final c = await open();
    c.onPageOpened();
    await settle();
    c.clearForLogout();
    FakeApi.calls.clear();

    expect(c.courses, isEmpty);
    c.onPageOpened();
    await settle();
    expect(c.courses, hasLength(2));
    expect(courseFetches(), 2);
  });

  testWidgets('the page: reopening it shows the list at once and requests nothing', (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    FavoritesController.ensureRegistered();
    final c = Get.find<FavoritesController>();

    Future<void> showPage() async {
      await tester.pumpWidget(auditApp(locale: 'ar', scale: 1, boundaryKey: GlobalKey(), child: const FavoritesView()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await showPage();
    expect(c.courses, hasLength(2));
    final first = courseFetches();
    expect(first, 2);

    await tester.pumpWidget(const SizedBox()); // الصفحة أُغلقت، والمتحكّم باقٍ
    expect(Get.isRegistered<FavoritesController>(), isTrue);
    await showPage();
    expect(courseFetches(), first, reason: 'second visit: no download');
    expect(c.isLoading.value, isFalse);
  });
}
