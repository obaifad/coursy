import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/courses_views.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// صور حقيقية: مسار الصورة فيه LayoutBuilder — يجب ألا يقع داخل IntrinsicHeight (كان يرمي على الهاتف فقط).
List<CourseModel> _withImages() =>
    sampleCourses().map((c) => c.copyWith(imageUrl: 'https://coursy.sy/storage/c${c.id}.jpg')).toList();

/// الصورة الحقيقية تُعرض (لا البديل)، ولا IntrinsicHeight فوق البطاقة ولا داخلها.
void _expectRealImageWithoutIntrinsicHeight(WidgetTester tester) {
  final cards = find.byType(CourseAuroraCard);
  expect(find.descendant(of: cards, matching: find.byType(AppNetworkImage)), findsWidgets);
  expect(find.descendant(of: cards, matching: find.byType(IntrinsicHeight)), findsNothing);
  expect(find.ancestor(of: cards.first, matching: find.byType(IntrinsicHeight)), findsNothing);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'ar',
  double width = 360,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Get.locale = Locale(locale);
  await tester.pumpWidget(auditApp(child: child, locale: locale, scale: scale, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _tile(CourseModel course, {VoidCallback? onTap, double width = 164}) => Center(
  child: SizedBox(
    width: width,
    child: CourseAuroraCard(course: course, onTap: onTap),
  ),
);

/// اللوح الزجاجي = منطقة BackdropFilter داخل البطاقة.
Rect _panel(WidgetTester tester) =>
    tester.getRect(find.descendant(of: find.byType(CourseAuroraCard), matching: find.byType(BackdropFilter)));

Matrix4 _transform(WidgetTester tester) => tester
    .widget<AnimatedContainer>(
      find.descendant(of: find.byType(CourseAuroraCard), matching: find.byType(AnimatedContainer)).first,
    )
    .transform!;

/// /courses بصور حقيقية — لصفحة «كل الدورات» كما على الهاتف.
class _ImageCourses extends CourseRepository {
  _ImageCourses(super.client, super.rating);

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    final items = _withImages();
    return PaginatedResult(items: items, currentPage: 1, lastPage: 1, total: items.length, hasMore: false);
  }

  @override
  Future<List<CourseModel>> fetchCourses({Map<String, dynamic>? query}) async => _withImages();
}

void main() {
  setUpAll(loadAuditFonts);
  setUp(Get.reset);

  group('aurora glass card', () {
    for (final locale in ['ar', 'en']) {
      testWidgets('title, institute, price and rating sit on the frosted panel ($locale)', (tester) async {
        final course = sampleCourses().first;
        var taps = 0;
        await _pump(tester, _tile(course, onTap: () => taps++), locale: locale);
        expect(tester.takeException(), isNull);

        final spec = CourseCardMetrics.auroraSpec(164);
        final card = tester.getRect(find.byType(CourseAuroraCard));
        expect(card.height, spec.height);

        final panel = _panel(tester);
        expect(panel.height, spec.panelHeight);
        expect(panel.bottom, card.bottom - CourseAuroraSpec.inset);
        expect(panel.left, card.left + CourseAuroraSpec.inset);
        expect(panel.right, card.right - CourseAuroraSpec.inset);

        final title = find.text(course.title);
        expect(tester.getRect(title).top, greaterThanOrEqualTo(panel.top));
        expect(tester.getRect(title).bottom, lessThanOrEqualTo(panel.bottom));
        expect(tester.widget<Text>(title).style?.color, Colors.white);
        expect(tester.widget<Text>(title).style?.fontWeight, FontWeight.w800);

        // السعر في جهة البداية والتقييم في جهة النهاية، كلاهما في السطر الأخير من اللوح.
        final price = tester.getRect(find.textContaining(course.price.split(' ').first, findRichText: true).last);
        final rating = tester.getRect(find.text(course.rating.toStringAsFixed(1)));
        expect(price.bottom, lessThanOrEqualTo(panel.bottom));
        expect((price.center.dy - rating.center.dy).abs(), lessThan(6));
        if (locale == 'ar') {
          expect(price.center.dx, greaterThan(rating.center.dx));
        } else {
          expect(price.center.dx, lessThan(rating.center.dx));
        }

        await tester.tap(find.byType(CourseAuroraCard));
        await tester.pump(const Duration(milliseconds: 300));
        expect(taps, 1);
      });
    }

    testWidgets('the frost is a real backdrop blur, clipped to the panel corners', (tester) async {
      await _pump(tester, _tile(sampleCourses().first));
      final filter = find.descendant(of: find.byType(CourseAuroraCard), matching: find.byType(BackdropFilter));
      expect(filter, findsOneWidget);
      final clip = tester.widget<ClipRRect>(find.ancestor(of: filter, matching: find.byType(ClipRRect)).first);
      expect(clip.borderRadius, AppCorners.md);
    });

    testWidgets('a course without ratings says so instead of showing grey stars', (tester) async {
      final unrated = CourseModel.fromJson({'id': 9, 'title_ar': 'تصميم', 'price': '0', 'reviews_count': 0});
      await _pump(tester, _tile(unrated));
      expect(tester.takeException(), isNull);
      expect(find.text('rating_none_short'.tr), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('a real image URL renders the network image with no IntrinsicHeight around it', (tester) async {
      for (final course in _withImages()) {
        await _pump(tester, _tile(course));
        expect(tester.takeException(), isNull, reason: course.title);
        _expectRealImageWithoutIntrinsicHeight(tester);
        expect(tester.getRect(find.byType(CourseAuroraCard)).height, CourseCardMetrics.auroraSpec(164).height);
      }
    });

    testWidgets('pressing tilts the card toward the finger; releasing settles it', (tester) async {
      await _pump(tester, _tile(sampleCourses().first));
      final rest = _transform(tester).clone();

      final card = tester.getRect(find.byType(CourseAuroraCard));
      final gesture = await tester.startGesture(card.topLeft + const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_transform(tester), isNot(equals(rest)));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_transform(tester), equals(rest));
    });

    testWidgets('reduced motion: no tilt', (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _tile(sampleCourses().first),
          ),
        ),
      );
      final rest = _transform(tester).clone();
      final gesture = await tester.startGesture(
        tester.getRect(find.byType(CourseAuroraCard)).topLeft + const Offset(20, 20),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_transform(tester), equals(rest));
      await gesture.up();
    });

    for (final (width, scale) in [(320.0, 1.0), (320.0, 1.3), (390.0, 1.0), (768.0, 1.3)]) {
      for (final images in [false, true]) {
        final label = '${width.toInt()}px, x$scale${images ? ', real images' : ''}';
        testWidgets('the grid fits every tile without overflow ($label)', (tester) async {
          final courses = images ? _withImages() : sampleCourses();
          await _pump(
            tester,
            Builder(
              builder: (context) => GridView.builder(
                padding: EdgeInsets.all(AppLayout.horizontalPage(context)),
                gridDelegate: AppGridLayouts.auroraGridFor(context),
                itemCount: courses.length,
                itemBuilder: (_, i) => CourseAuroraCard(course: courses[i]),
              ),
            ),
            width: width,
            scale: scale,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(CourseAuroraCard), findsNWidgets(courses.length));
          if (images) _expectRealImageWithoutIntrinsicHeight(tester);
        });
      }
    }
  });

  group('courses page card style', () {
    Future<void> pumpCourses(WidgetTester tester, Widget view, {bool images = false}) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      if (images) {
        Get.delete<CourseRepository>(force: true);
        Get.put<CourseRepository>(_ImageCourses(Get.find(), Get.find()));
      }
      Get.put(CoursesController());
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.locale = const Locale('ar');
      await tester.pumpWidget(auditApp(child: view, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    test('Aurora Glass is the default and the boarding pass stays available', () {
      expect(CoursesView.defaultCardStyle, CourseCardStyle.auroraGlass);
      expect(CourseCardStyle.values, containsAll([CourseCardStyle.auroraGlass, CourseCardStyle.boardingPass]));
    });

    testWidgets('All Courses shows Aurora Glass cards by default', (tester) async {
      await pumpCourses(tester, const CoursesView());
      expect(tester.takeException(), isNull);
      expect(find.byType(CourseAuroraCard), findsWidgets);
      expect(find.byType(CourseBoardingCard), findsNothing);
    });

    testWidgets('All Courses with real course images: Aurora renders them, no IntrinsicHeight', (tester) async {
      await pumpCourses(tester, const CoursesView(), images: true);
      expect(tester.takeException(), isNull);
      expect(find.byType(CourseAuroraCard), findsWidgets);
      _expectRealImageWithoutIntrinsicHeight(tester);
    });

    testWidgets('one value switches All Courses back to the boarding-pass cards', (tester) async {
      await pumpCourses(tester, const CoursesView(cardStyle: CourseCardStyle.boardingPass));
      expect(tester.takeException(), isNull);
      expect(find.byType(CourseBoardingCard), findsWidgets);
      expect(find.byType(CourseAuroraCard), findsNothing);
    });
  });
}
