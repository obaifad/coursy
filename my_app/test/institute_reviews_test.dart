import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/institute_repository.dart';
import 'package:my_app/core/data/repositories/review_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/utils/app_toast.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/widgets/review_card.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// تقييم المعاهد: الخادم صار يقبل `POST /institutes/{id}/reviews` و`DELETE .../reviews/mine`، ويرسل
/// `can_review` و`my_review` مع التفاصيل و`type` على كل تقييم.

// ---------- HTTP: شكل الطلبات ----------

class _Recorder implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 201;
  Object? body = {
    'id': 9,
    'rating': 4,
    'comment': 'جيد',
    'type': 'institute',
    'course': null,
    'student': {'id': 7, 'name': 'Omar K.'},
  };

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o);
    if (body == null) return ResponseBody.fromString('', status);
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ---------- خادم وهمي على مستوى المستودعات ----------

class _Institutes extends InstituteRepository {
  _Institutes(super.client);

  Map<String, dynamic> json = {
    'id': 56,
    'name_ar': 'معهد النخبة',
    'name_en': 'Elite',
    'average_rating': '0.00',
    'reviews_count': 0,
    'can_review': true,
    'my_review': null,
  };

  @override
  Future<InstituteModel> fetchInstituteById(int id) async => InstituteModel.fromJson(Map.of(json));
}

class _Reviews extends ReviewRepository {
  _Reviews(super.client, this.institutes);
  final _Institutes institutes;

  final posts = <({int rating, String comment})>[];
  int deletes = 0;
  ApiException? postFailure;
  final list = <Map<String, dynamic>>[
    {
      'id': 1,
      'rating': 3,
      'comment': 'دورة جيدة',
      'type': 'course',
      'course': {'id': 4, 'title': 'Flutter'},
      'student': {'id': 8, 'name': 'Sara H.'},
    },
  ];

  void _sync() {
    final ratings = list.map((r) => r['rating'] as int).toList();
    institutes.json['reviews_count'] = ratings.length;
    institutes.json['average_rating'] = ratings.isEmpty
        ? '0.00'
        : (ratings.reduce((a, b) => a + b) / ratings.length).toStringAsFixed(2);
  }

  @override
  Future<List<ReviewModel>> fetchReviews({int? courseId, int? instituteId, int? instructorId}) async =>
      list.map(ReviewModel.fromJson).toList();

  @override
  Future<ReviewModel> submitInstituteReview({
    required int instituteId,
    required int rating,
    required String comment,
  }) async {
    if (postFailure != null) throw postFailure!;
    posts.add((rating: rating, comment: comment));
    final mine = {
      'id': 99,
      'rating': rating,
      'comment': comment,
      'type': 'institute',
      'course': null,
      'student': {'id': 7, 'name': 'Omar K.'},
    };
    list.removeWhere((r) => r['id'] == 99);
    list.insert(0, mine);
    institutes.json['my_review'] = mine;
    _sync();
    return ReviewModel.fromJson(mine);
  }

  @override
  Future<void> deleteMyInstituteReview(int instituteId) async {
    deletes++;
    list.removeWhere((r) => r['id'] == 99);
    institutes.json['my_review'] = null;
    _sync();
  }
}

void main() {
  final toasts = <String>[];
  setUpAll(loadAuditFonts);
  setUp(() {
    toasts.clear();
    AppToast.onShow = (title, message, _) => toasts.add(message);
  });
  tearDown(() {
    AppToast.onShow = null;
    Get.reset();
  });

  group('parsing', () {
    test('institute details carry can_review, my_review and reviews_count', () {
      final i = InstituteModel.fromJson({
        'id': 56,
        'average_rating': '4.00',
        'reviews_count': 2,
        'can_review': true,
        'my_review': {'id': 9, 'rating': 4, 'comment': 'جيد', 'type': 'institute', 'course': null},
      });
      expect(i.canReview, isTrue);
      expect(i.myReview?.rating, 4);
      expect(i.myReview?.isInstituteReview, isTrue);
      expect(i.reviewsCount, 2);
    });

    test('without a token: can_review false, my_review null', () {
      final i = InstituteModel.fromJson({'id': 56, 'can_review': false, 'my_review': null});
      expect(i.canReview, isFalse);
      expect(i.myReview, isNull);
    });

    test('review type: "course" and "institute"', () {
      expect(ReviewModel.fromJson({'id': 1, 'rating': 5, 'type': 'course'}).isInstituteReview, isFalse);
      expect(ReviewModel.fromJson({'id': 2, 'rating': 5, 'type': 'institute'}).isInstituteReview, isTrue);
      expect(ReviewModel.fromJson({'id': 3, 'rating': 5}).isInstituteReview, isFalse);
    });

    test('copyWith can clear my_review', () {
      final i = InstituteModel.fromJson({
        'id': 1,
        'my_review': {'id': 9, 'rating': 4},
      });
      expect(i.copyWith(rating: 1).myReview, isNotNull);
      expect(i.copyWith(clearMyReview: true).myReview, isNull);
    });
  });

  group('requests', () {
    late _Recorder server;
    late ReviewRepository repo;

    setUp(() async {
      await registerFakes(loggedIn: true, locale: 'ar');
      final client = Get.find<ApiClient>();
      server = _Recorder();
      client.dio.httpClientAdapter = server;
      repo = ReviewRepository(client);
    });

    test('submit posts rating and comment as JSON body to /institutes/{id}/reviews', () async {
      final saved = await repo.submitInstituteReview(instituteId: 56, rating: 4, comment: '  جيد  ');
      final r = server.requests.single;
      expect(r.method, 'POST');
      expect(r.path, '/institutes/56/reviews');
      expect(r.queryParameters, isEmpty, reason: 'not in the query string like course reviews');
      expect(r.data, {'rating': 4, 'comment': 'جيد'});
      expect(saved.id, 9);
      expect(saved.isInstituteReview, isTrue);
    });

    test('an empty comment is left out and the rating is kept within 1-5', () async {
      await repo.submitInstituteReview(instituteId: 56, rating: 9, comment: '   ');
      expect(server.requests.single.data, {'rating': 5});
    });

    test('delete sends DELETE /institutes/{id}/reviews/mine and accepts an empty 204', () async {
      server
        ..status = 204
        ..body = null;
      await repo.deleteMyInstituteReview(56);
      final r = server.requests.single;
      expect(r.method, 'DELETE');
      expect(r.path, '/institutes/56/reviews/mine');
    });

    test('403 (not eligible) surfaces the server message', () async {
      server
        ..status = 403
        ..body = {'message': 'You need an approved enrollment.'};
      await expectLater(
        repo.submitInstituteReview(instituteId: 56, rating: 4, comment: ''),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'You need an approved enrollment.')),
      );
    });
  });

  group('controller', () {
    late _Institutes institutes;
    late _Reviews reviews;

    Future<InstituteDetailsController> open({InstituteModel? seed, bool noReviews = false}) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      final client = Get.find<ApiClient>();
      institutes = replaceFake<InstituteRepository>(_Institutes(client)) as _Institutes;
      reviews = replaceFake<ReviewRepository>(_Reviews(client, institutes)) as _Reviews;
      if (noReviews) reviews.list.clear();
      reviews._sync();
      Get.routing.args = seed ?? InstituteModel.fromJson({'id': 56, 'name_ar': 'معهد النخبة'});
      final c = Get.put(InstituteDetailsController(), tag: 'r');
      await c.loadDetails();
      return c;
    }

    test('loads reviews with the details', () async {
      final c = await open();
      expect(c.reviews.single.courseTitle, 'Flutter');
      expect(c.institute.value!.canReview, isTrue);
      expect(c.institute.value!.reviewsCount, 1);
    });

    test('submitting saves the review, then rating, count and my_review come from the server', () async {
      final c = await open();
      c.reviewRating.value = 5;
      c.reviewCommentController.text = 'تنظيم ممتاز';
      await c.submitReview();

      expect(reviews.posts.single, (rating: 5, comment: 'تنظيم ممتاز'));
      final i = c.institute.value!;
      expect(i.myReview?.rating, 5);
      expect(i.reviewsCount, 2);
      expect(i.rating, 4.0, reason: '(3 + 5) / 2 from the server');
      expect(c.reviews.first.isInstituteReview, isTrue);
      expect(c.reviewCommentController.text, isEmpty);
      expect(toasts, ['review_submitted_msg'.tr]);
    });

    test('editing re-sends and keeps one review', () async {
      final c = await open();
      await c.submitReview();
      c.startEditingReview();
      expect(c.isEditingReview.value, isTrue);
      expect(c.reviewRating.value, 5, reason: 'the form starts from the saved review');
      c.reviewRating.value = 2;
      await c.submitReview();

      expect(reviews.posts.map((p) => p.rating), [5, 2]);
      expect(c.reviews.where((r) => r.isInstituteReview), hasLength(1));
      expect(c.institute.value!.myReview?.rating, 2);
      expect(c.isEditingReview.value, isFalse);
      expect(toasts.last, 'institute_review_updated_msg'.tr);
    });

    test('not eligible: nothing is sent', () async {
      final c = await open();
      c.institute.value = c.institute.value!.copyWith(canReview: false);
      await c.submitReview();
      expect(reviews.posts, isEmpty);
      expect(toasts, ['institute_review_not_eligible'.tr]);
    });

    test('a server refusal is shown and the form stays', () async {
      final c = await open();
      reviews.postFailure = ApiException('Not eligible.', statusCode: 403);
      c.reviewCommentController.text = 'نص';
      await c.submitReview();
      expect(toasts, ['Not eligible.']);
      expect(c.institute.value!.myReview, isNull);
      expect(c.reviewCommentController.text, 'نص', reason: 'the text is not lost');
      expect(c.isSubmittingReview.value, isFalse);
    });

    test('deleting the only institute review drops the rating back to the server value', () async {
      final c = await open(noReviews: true);
      await c.submitReview();
      expect(c.institute.value!.rating, 5.0);

      await c.deleteMyReview();
      expect(reviews.deletes, 1);
      final i = c.institute.value!;
      expect(i.myReview, isNull);
      expect(i.reviewsCount, 0);
      expect(i.rating, 0, reason: 'the previous 5.0 must not stick when the server says 0 with a count');
      expect(toasts.last, 'institute_review_deleted_msg'.tr);
    });

    test('a stale list rating (the old seeded 5.00) is replaced by the details value', () async {
      final seed = InstituteModel.fromJson({'id': 56, 'name_ar': 'معهد', 'average_rating': '5.00'});
      expect(seed.rating, 5.0);
      final c = await open(seed: seed, noReviews: true);
      expect(c.institute.value!.rating, 0);
      expect(c.institute.value!.reviewsCount, 0);
    });
  });

  group('reviews tab', () {
    Future<InstituteDetailsController> pump(
      WidgetTester tester, {
      required bool loggedIn,
      Map<String, dynamic> extra = const {},
    }) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await registerFakes(loggedIn: loggedIn, locale: 'ar');
      final client = Get.find<ApiClient>();
      final institutes = replaceFake<InstituteRepository>(_Institutes(client)) as _Institutes;
      institutes.json.addAll(extra);
      final reviews = replaceFake<ReviewRepository>(_Reviews(client, institutes)) as _Reviews;
      reviews._sync();
      reviews.list.add({
        'id': 5,
        'rating': 4,
        'comment': 'مكان مريح',
        'type': 'institute',
        'course': null,
        'student': {'id': 9, 'name': 'Lina M.'},
      });
      Get.routing.args = InstituteModel.fromJson({'id': 56, 'name_ar': 'معهد النخبة'});
      final c = Get.put(InstituteDetailsController(), tag: 'tab');
      await tester.pumpWidget(
        auditApp(
          child: const InstituteDetailsView(controllerTag: 'tab'),
          locale: 'ar',
          scale: 1,
          boundaryKey: GlobalKey(),
        ),
      );
      await tester.runAsync(c.loadDetails);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('tab_reviews'.tr));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      return c;
    }

    testWidgets('the page has a Reviews tab; each review is labelled by type', (tester) async {
      await pump(tester, loggedIn: true);
      expect(find.byType(ReviewCard), findsNWidgets(2));
      expect(find.text('review_type_institute'.tr), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget, reason: 'course reviews show the course');
    });

    testWidgets('eligible student without a review sees the form', (tester) async {
      await pump(tester, loggedIn: true);
      expect(find.text('institute_rate_title'.tr), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('submit_review'.tr), findsOneWidget);
    });

    testWidgets('not eligible: a hint instead of the form', (tester) async {
      await pump(tester, loggedIn: true, extra: {'can_review': false});
      expect(find.text('institute_review_not_eligible'.tr), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('logged out: a login hint, no form', (tester) async {
      await pump(tester, loggedIn: false, extra: {'can_review': false});
      expect(find.text('institute_review_login_hint'.tr), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('with a review: shown with edit and delete; edit opens the form filled in', (tester) async {
      final c = await pump(
        tester,
        loggedIn: true,
        extra: {
          'my_review': {'id': 99, 'rating': 3, 'comment': 'تعليقي', 'type': 'institute', 'course': null},
        },
      );
      expect(find.text('institute_your_review'.tr), findsOneWidget);
      expect(find.text('تعليقي'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('institute_review_edit'.tr));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(c.reviewCommentController.text, 'تعليقي');
      expect(c.reviewRating.value, 3);
      expect(find.text('institute_review_save'.tr), findsOneWidget);
    });
  });
}
