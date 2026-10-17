import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/data/repositories/search_repository.dart';
import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/modules/search/controllers/search_controller.dart';
import 'package:my_app/modules/search/views/search_view.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

typedef _Call = ({String query, SearchScope scope, String? level, int? cityId});

/// يسجّل كل طلب بحث ويرجع نتائج حسب النطاق — فلتر المستوى يُبقي دورة واحدة.
class _RecordingSearch extends SearchRepository {
  _RecordingSearch(super.client, super.rating);

  final calls = <_Call>[];

  @override
  Future<SearchResult> search({
    required String query,
    SearchScope scope = SearchScope.all,
    int limit = 12,
    int? categoryId,
    int? cityId,
    String? level,
    String? studyType,
    int? instituteId,
    bool? featured,
    bool? verified,
  }) async {
    calls.add((query: query, scope: scope, level: level, cityId: cityId));
    bool wants(SearchScope type) => scope == SearchScope.all || scope == type;
    final courses = level == null ? sampleCourses() : sampleCourses().take(1).toList();
    return SearchResult(
      courses: wants(SearchScope.courses) ? courses : const [],
      institutes: wants(SearchScope.institutes) ? sampleInstitutes() : const [],
      instructors: wants(SearchScope.instructors) ? sampleInstructors() : const [],
    );
  }
}

final _courses = sampleCourses().length;
final _institutes = sampleInstitutes().length;
final _instructors = sampleInstructors().length;

Future<(SearchPageController, _RecordingSearch)> _setUp() async {
  await registerFakes(loggedIn: true, locale: 'ar');
  Get.delete<SearchRepository>(force: true);
  final repo = Get.put<SearchRepository>(_RecordingSearch(Get.find(), Get.find())) as _RecordingSearch;
  final controller = Get.put(SearchPageController());
  return (controller, repo);
}

/// يكتب النص وينتظر مهلة البحث التلقائي.
Future<void> _type(WidgetTester tester, SearchPageController c, String text) async {
  c.queryController.text = text;
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _pumpView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Get.locale = const Locale('ar');
  await tester.pumpWidget(auditApp(child: const SearchView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(loadAuditFonts);

  group('scope counts', () {
    testWidgets('one "all" search fills every tab count', (tester) async {
      final (c, repo) = await _setUp();
      await _type(tester, c, 'فلاتر');

      expect(repo.calls.map((call) => call.scope), [SearchScope.all]);
      expect(c.countFor(SearchScope.courses), _courses);
      expect(c.countFor(SearchScope.institutes), _institutes);
      expect(c.countFor(SearchScope.instructors), _instructors);
      expect(c.countFor(SearchScope.all), _courses + _institutes + _instructors);
    });

    testWidgets('switching tabs runs only the scoped search and keeps the other counts', (tester) async {
      final (c, repo) = await _setUp();
      await _type(tester, c, 'فلاتر');
      repo.calls.clear();

      c.setScope(SearchScope.institutes);
      await tester.pump();

      expect(repo.calls.map((call) => call.scope), [SearchScope.institutes]);
      expect(c.courses, isEmpty);
      expect(c.institutes.length, _institutes);
      expect(c.countFor(SearchScope.courses), _courses);
      expect(c.countFor(SearchScope.all), _courses + _institutes + _instructors);
    });

    testWidgets('a new query on a scoped tab also refreshes the other counts', (tester) async {
      final (c, repo) = await _setUp();
      c.setScope(SearchScope.courses);
      await tester.pump();
      repo.calls.clear();

      await _type(tester, c, 'PMP');

      expect(repo.calls.map((call) => call.scope).toSet(), {SearchScope.courses, SearchScope.all});
      expect(c.countFor(SearchScope.instructors), _instructors);
      expect(c.countFor(SearchScope.courses), _courses);
    });

    testWidgets('clearing the query clears the counts', (tester) async {
      final (c, _) = await _setUp();
      await _type(tester, c, 'فلاتر');
      await _type(tester, c, '');
      expect(c.scopeCounts, isEmpty);
    });
  });

  group('filters', () {
    testWidgets('preview counts the draft without applying it', (tester) async {
      final (c, repo) = await _setUp();
      await _type(tester, c, 'فلاتر');
      repo.calls.clear();

      c.previewFilters(const SearchFilters(level: 'beginner'));
      expect(c.isPreviewing.value, isTrue);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(c.previewCount.value, 1 + _institutes + _instructors);
      expect(c.isPreviewing.value, isFalse);
      expect(repo.calls.single.level, 'beginner');
      expect(c.selectedLevel.value, isEmpty, reason: 'not applied yet');
    });

    testWidgets('the applied filters need no preview request', (tester) async {
      final (c, repo) = await _setUp();
      await _type(tester, c, 'فلاتر');
      repo.calls.clear();

      c.previewFilters(c.appliedFilters);
      expect(c.previewCount.value, _courses + _institutes + _instructors);
      expect(repo.calls, isEmpty);
    });

    testWidgets('removing one filter keeps the others and searches again', (tester) async {
      final (c, repo) = await _setUp();
      c.applyFilters(level: 'beginner', cityId: 1);
      await tester.pump();
      repo.calls.clear();

      c.removeFilter(SearchFilterKind.level);
      await tester.pump();

      expect(c.selectedLevel.value, isEmpty);
      expect(c.selectedCityId.value, 1);
      expect(repo.calls.single.level, isNull);
      expect(repo.calls.single.cityId, 1);
    });
  });

  group('search view', () {
    testWidgets('scope tabs are visible with live counts and switch the controller scope', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      for (final label in ['الكل', 'دورات', 'معاهد', 'مدرّبون']) {
        expect(find.text(label), findsOneWidget);
      }
      // بلا بحث: بلا أعداد.
      expect(find.text('$_courses'), findsNothing);

      await tester.enterText(find.byType(TextField), 'فلاتر');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('${_courses + _institutes + _instructors}'), findsOneWidget);
      expect(find.text('$_instructors'), findsWidgets);

      await tester.tap(find.text('معاهد'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.selectedScope.value, SearchScope.institutes);
      expect(find.byType(CourseRowCard), findsNothing);
      expect(find.byType(InstituteListCard), findsNWidgets(_institutes));
    });

    testWidgets('results use compact rows', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      await tester.enterText(find.byType(TextField), 'فلاتر');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CourseRowCard), findsWidgets);
      expect(find.byType(AppRowCard), findsWidgets);
      expect(c.hasAnyResults, isTrue);
    });

    testWidgets('active filters show as chips with ✕ and a "clear all" action', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      c.applyFilters(level: 'beginner', cityId: 1);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('مبتدئ'), findsOneWidget);
      expect(find.text('دمشق'), findsWidgets); // الشريحة + مدينة المعاهد في النتائج
      expect(find.text('مسح الكل'), findsOneWidget);
      expect(find.byTooltip('remove_filter'.tr), findsNWidgets(2));

      await tester.tap(find.byTooltip('remove_filter'.tr).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.activeFiltersCount, 1);

      await tester.tap(find.text('مسح الكل'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.hasActiveFilters, isFalse);
      expect(find.text('مسح الكل'), findsNothing);
    });

    testWidgets('the header is the Brand Bar of the list screens, its pill shows the result count', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      expect(find.byType(AppBrandSliverAppBar), findsOneWidget);
      expect(find.text('search_subtitle'.tr), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'فلاتر');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      final total = _courses + _institutes + _instructors;
      expect(c.countFor(SearchScope.all), total);
      expect(find.text(pluralTr('search_results_count', total)), findsOneWidget);
    });

    testWidgets('the filter button sits inside the search bar and counts the active filters', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      final bar = tester.getRect(
        find.ancestor(of: find.byType(TextField), matching: find.byType(AnimatedContainer)).first,
      );
      final button = tester.getRect(find.byTooltip('search_filters'.tr));
      expect(bar.contains(button.center), isTrue);
      expect(button.height, lessThanOrEqualTo(bar.height));

      c.applyFilters(level: 'beginner', cityId: 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.descendant(of: find.byTooltip('search_filters'.tr), matching: find.text('2')), findsOneWidget);
    });

    testWidgets('scope tabs use the segmented-tab colours of the rest of the app', (tester) async {
      await _setUp();
      await _pumpView(tester);
      expect(tester.widget<Text>(find.text('الكل')).style?.color, AppColors.primaryInk);
      expect(tester.widget<Text>(find.text('دورات')).style?.color, AppColors.textSecondary);
    });

    testWidgets('the field, tabs and chips stay pinned under the collapsed header', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      c.applyFilters(level: 'beginner');
      await tester.enterText(find.byType(TextField), 'فلاتر');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      // أكثر من مسافة انطواء الرأس وأقل من نهاية القائمة (بلا تمدد الحافة).
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 600));
      final field = tester.getRect(find.byType(TextField));
      expect(field.top, greaterThanOrEqualTo(AppBrandSliverAppBar.toolbarHeight));
      expect(field.top, lessThan(AppBrandSliverAppBar.toolbarHeight + 40));
      expect(find.text('مسح الكل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recent searches are app chips that run the search when tapped', (tester) async {
      final (c, repo) = await _setUp();
      await _pumpView(tester);
      expect(find.text('عمليات بحث حديثة'), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);

      await tester.tap(find.text('Business English'));
      // بعد مهلة البحث التلقائي أيضاً — لا مؤقّت معلّق.
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.queryText.value, 'Business English');
      expect(repo.calls.last.query, 'Business English');
    });

    testWidgets('the filter sheet is one level of chip groups with a live "show X results" button', (tester) async {
      final (c, _) = await _setUp();
      await _pumpView(tester);
      await tester.enterText(find.byType(TextField), 'فلاتر');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip('search_filters'.tr));
      await tester.pumpAndSettle();
      for (final group in ['التصنيف', 'المحافظة', 'المستوى', 'نوع الدراسة']) {
        expect(find.text(group), findsOneWidget);
      }
      final total = _courses + _institutes + _instructors;
      expect(find.text(pluralTr('search_show_results', total)), findsOneWidget);

      await tester.tap(find.text('مبتدئ'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));
      final narrowed = 1 + _institutes + _instructors;
      expect(find.text(pluralTr('search_show_results', narrowed)), findsOneWidget);

      await tester.tap(find.text(pluralTr('search_show_results', narrowed)));
      await tester.pumpAndSettle();
      expect(c.selectedLevel.value, 'beginner');
      expect(find.text('مسح الكل'), findsOneWidget);
    });
  });
}
