import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/favorites_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/favorite_model.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/favorites_service.dart';
import 'package:my_app/core/services/student_id_resolver.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/course_favorite_button.dart';

import 'layout/fakes.dart';
import 'layout/sample_data.dart';

/// مستودع مفضلة يمكن تعليق ردّه — لرؤية الحالة أثناء الطلب.
class _SlowFavorites extends FavoritesRepository {
  _SlowFavorites(super.client, super.resolver);

  int adds = 0;
  int removes = 0;
  Completer<void>? gate;

  @override
  Future<List<FavoriteModel>> fetchMine() async => [];

  @override
  Future<Map<String, dynamic>> addFavorite({int? courseId, int? instituteId, int? instructorId}) async {
    adds++;
    await gate?.future;
    return {'id': 50 + adds, 'course_id': courseId};
  }

  @override
  Future<void> removeFavorite(int favoriteId, {int? courseId}) async {
    removes++;
    await gate?.future;
  }
}

Future<(FavoritesService, _SlowFavorites)> _setup({required bool loggedIn}) async {
  final tokens = await registerFakes(loggedIn: loggedIn, locale: 'ar');
  final repo = _SlowFavorites(Get.find<ApiClient>(), Get.find<StudentIdResolver>());
  Get.delete<FavoritesService>(force: true);
  final service = Get.put(FavoritesService(repo, tokens));
  return (service, repo);
}

Widget _app(Widget child, {String locale = 'ar'}) => GetMaterialApp(
  locale: Locale(locale),
  home: Directionality(
    textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(body: Center(child: child)),
  ),
);

Finder get _heart => find.byType(CourseFavoriteButton);

void main() {
  tearDown(Get.reset);

  testWidgets('flips at once, sends one request for a double tap, then follows the server', (tester) async {
    final (service, repo) = await _setup(loggedIn: true);
    repo.gate = Completer<void>();
    await tester.pumpWidget(_app(const CourseFavoriteButton(courseId: 7)));

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(_heart);
    await tester.pump();
    await tester.tap(_heart);
    await tester.pump(const Duration(milliseconds: 250));

    // ممتلئ فوراً قبل ردّ الخادم، وطلب واحد فقط.
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(repo.adds, 1);

    repo.gate!.complete();
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(service.isCourseFavorite(7), isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(tester.getSemantics(_heart).label, 'favorite_remove');
  });

  testWidgets('the same course in two cards toggles once', (tester) async {
    final (_, repo) = await _setup(loggedIn: true);
    repo.gate = Completer<void>();
    await tester.pumpWidget(
      _app(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [CourseFavoriteButton(courseId: 7), CourseFavoriteButton(courseId: 7)],
        ),
      ),
    );

    await tester.tap(_heart.first);
    await tester.tap(_heart.last);
    await tester.pump();
    expect(repo.adds, 1);

    repo.gate!.complete();
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('a guest gets the login prompt and the heart does not flip', (tester) async {
    final (_, repo) = await _setup(loggedIn: false);
    await tester.pumpWidget(_app(const CourseFavoriteButton(courseId: 7)));

    await tester.tap(_heart);
    await tester.pumpAndSettle();

    expect(find.text('login_required_title'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(repo.adds, 0);

    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('on the course card the heart never covers the badge ($locale)', (tester) async {
      await _setup(loggedIn: true);
      // دورة رقم 1 مميزة → شارة «الأكثر طلباً» في زاوية النهاية.
      final course = sampleCourses().first;
      for (final width in [150.0, 170.0, 270.0]) {
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: width,
              height: 420,
              child: CourseCard(course: course),
            ),
            locale: locale,
          ),
        );
        await tester.pump();

        final heart = tester.getRect(_heart);
        final badge = tester.getRect(find.text('course_badge_bestseller'));
        final card = tester.getRect(find.byType(CourseCard));
        expect(heart.overlaps(badge), isFalse, reason: 'width $width');
        // البداية: يمين بالعربية ويسار بالإنجليزية؛ الشارة في الجهة الأخرى.
        if (locale == 'ar') {
          expect(heart.right, greaterThan(card.center.dx));
          expect(badge.left, lessThan(card.center.dx));
        } else {
          expect(heart.left, lessThan(card.center.dx));
          expect(badge.right, greaterThan(card.center.dx));
        }
      }
    });
  }

  testWidgets('a card can hide the heart', (tester) async {
    await _setup(loggedIn: true);
    final CourseModel course = sampleCourses()[1];
    await tester.pumpWidget(
      _app(SizedBox(width: 170, height: 420, child: CourseCard(course: course, showFavorite: false))),
    );
    expect(_heart, findsNothing);
  });

  testWidgets('a failed request puts the heart back', (tester) async {
    final tokens = await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _FailingFavorites(Get.find<ApiClient>(), Get.find<StudentIdResolver>());
    Get.delete<FavoritesService>(force: true);
    final service = Get.put(FavoritesService(repo, tokens));
    await service.syncFromApi(force: true);
    await tester.pumpWidget(_app(const CourseFavoriteButton(courseId: 1)));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(_heart);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(service.isCourseFavorite(1), isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}

class _FailingFavorites extends FavoritesRepository {
  _FailingFavorites(super.client, super.resolver);

  @override
  Future<List<FavoriteModel>> fetchMine() async => [
    FavoriteModel.fromJson({'id': 1, 'course_id': 1}),
  ];

  @override
  Future<void> removeFavorite(int favoriteId, {int? courseId}) async => throw Exception('offline');
}
