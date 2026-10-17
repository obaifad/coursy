import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/search_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/recent_search_storage.dart';

/// فلاتر البحث كقيمة واحدة — لمسودة ورقة الفلاتر ومقارنتها بالمطبّق.
class SearchFilters {
  const SearchFilters({this.cityId, this.categoryId, this.level, this.studyType});

  final int? cityId;
  final int? categoryId;
  final String? level;
  final String? studyType;

  bool get isEmpty => cityId == null && categoryId == null && (level ?? '').isEmpty && (studyType ?? '').isEmpty;

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.cityId == cityId &&
      other.categoryId == categoryId &&
      (other.level ?? '') == (level ?? '') &&
      (other.studyType ?? '') == (studyType ?? '');

  @override
  int get hashCode => Object.hash(cityId, categoryId, level ?? '', studyType ?? '');
}

/// نوع فلتر واحد — لإزالته منفرداً من شريط الفلاتر النشطة.
enum SearchFilterKind { category, city, level, studyType }

class SearchPageController extends GetxController with LatestLoadGuard {
  final SearchRepository _searchRepository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();
  final CityRepository _cityRepository = Get.find();
  final RecentSearchStorage _recentStorage = Get.find();

  final queryController = TextEditingController();

  final isSearching = false.obs;
  final errorMessage = RxnString();

  final selectedScope = SearchScope.all.obs;
  final selectedCityId = RxnInt();
  final selectedCategoryId = RxnInt();
  final selectedLevel = ''.obs;
  final selectedStudyType = ''.obs;

  final courses = <CourseModel>[].obs;
  final institutes = <InstituteModel>[].obs;
  final instructors = <InstructorModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final cities = <CityModel>[].obs;

  final totalCourses = 0.obs;
  final totalInstitutes = 0.obs;
  final totalInstructors = 0.obs;
  final queryText = ''.obs;

  /// عدد النتائج لكل تبويب نطاق في آخر بحث. تبويب النطاق الحالي من نتيجته، والباقي من طلب «الكل» موازٍ
  /// (يُعاد فقط حين يتغيّر النص أو الفلاتر — لا عند التنقل بين التبويبات). غياب المفتاح = غير معروف.
  final scopeCounts = <SearchScope, int>{}.obs;

  /// عدد النتائج لو طُبّقت مسودة ورقة الفلاتر (null = غير معروف بعد).
  final previewCount = RxnInt();
  final isPreviewing = false.obs;

  RxList<String> get recentQueries => _recentStorage.queries;

  Timer? _debounce;
  Timer? _previewDebounce;

  /// النص والفلاتر التي تخص أعداد [scopeCounts] الحالية.
  String? _countsKey;
  static const _limit = 12;

  SearchFilters get appliedFilters => SearchFilters(
    cityId: selectedCityId.value,
    categoryId: selectedCategoryId.value,
    level: selectedLevel.value.isEmpty ? null : selectedLevel.value,
    studyType: selectedStudyType.value.isEmpty ? null : selectedStudyType.value,
  );

  int? countFor(SearchScope scope) => scopeCounts[scope];

  bool get hasActiveFilters =>
      selectedCityId.value != null ||
      selectedCategoryId.value != null ||
      selectedLevel.value.isNotEmpty ||
      selectedStudyType.value.isNotEmpty;

  int get activeFiltersCount {
    var n = 0;
    if (selectedCityId.value != null) n++;
    if (selectedCategoryId.value != null) n++;
    if (selectedLevel.value.isNotEmpty) n++;
    if (selectedStudyType.value.isNotEmpty) n++;
    return n;
  }

  bool get hasAnyResults => courses.isNotEmpty || institutes.isNotEmpty || instructors.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    queryController.addListener(_onQueryChanged);
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final session = beginLoad('filters');
    try {
      final cats = await _categoryRepository.fetchCategories();
      applyIfCurrent(session, () => categories.assignAll(cats));
    } on ApiCancelledException {
      return;
    } catch (_) {}
    if (!shouldApply(session)) return;
    try {
      final cityList = await _cityRepository.fetchCities();
      applyIfCurrent(session, () => cities.assignAll(cityList));
    } on ApiCancelledException {
      return;
    } catch (_) {}
  }

  Future<void> reloadLocalizedData() => _loadFilters();

  void setScope(SearchScope scope) {
    if (selectedScope.value == scope) return;
    selectedScope.value = scope;
    runSearch(resetPage: true, saveRecent: false);
  }

  void _onQueryChanged() {
    queryText.value = queryController.text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 360), () => runSearch(resetPage: true, saveRecent: false));
  }

  Future<void> runSearch({bool resetPage = true, bool saveRecent = true, String? overrideQuery}) async {
    final text = (overrideQuery ?? queryController.text).trim();

    if (text.isEmpty && !hasActiveFilters) {
      // جلسة جديدة تُبطل بحثاً سابقاً ما زال جارياً — كانت نتائجه تعود بعد مسح الحقل.
      beginLoad();
      _clearResults();
      errorMessage.value = null;
      isSearching.value = false;
      return;
    }

    if (saveRecent && text.isNotEmpty) {
      await _recentStorage.add(text);
    }

    isSearching.value = true;
    errorMessage.value = null;

    final session = beginLoad();
    final scope = selectedScope.value;
    final filters = appliedFilters;
    final countsKey = _keyFor(text, filters);
    final keyChanged = countsKey != _countsKey;
    // أعداد التبويبات الأخرى تحتاج طلب «الكل» فقط إن تغيّر النص أو الفلاتر.
    final needsCounts = scope != SearchScope.all && keyChanged;

    try {
      final scopedFuture = _search(text, scope, filters);
      final countsFuture = needsCounts
          ? _search(text, SearchScope.all, filters).then<SearchResult?>((r) => r, onError: (Object _) => null)
          : Future<SearchResult?>.value();
      final result = await scopedFuture;
      final all = await countsFuture;

      applyIfCurrent(session, () {
        courses.assignAll(result.courses);
        institutes.assignAll(result.institutes);
        instructors.assignAll(result.instructors);
        totalCourses.value = result.totalCourses;
        totalInstitutes.value = result.totalInstitutes;
        totalInstructors.value = result.totalInstructors;
        _updateScopeCounts(scope, result, all: all, keyChanged: keyChanged);
        _countsKey = countsKey;
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) {
        errorMessage.value = userErrorMessage(e);
        _clearResults();
      }
    } finally {
      applyIfCurrent(session, () => isSearching.value = false);
    }
  }

  Future<SearchResult> _search(String text, SearchScope scope, SearchFilters filters) {
    return _searchRepository.search(
      query: text,
      scope: scope,
      limit: _limit,
      categoryId: filters.categoryId,
      cityId: filters.cityId,
      level: filters.level,
      studyType: filters.studyType,
    );
  }

  static String _keyFor(String text, SearchFilters f) =>
      [text, f.categoryId ?? '', f.cityId ?? '', f.level ?? '', f.studyType ?? ''].join('|');

  static int _countIn(SearchResult result, SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return result.totalCourses + result.totalInstitutes + result.totalInstructors;
      case SearchScope.courses:
        return result.totalCourses;
      case SearchScope.institutes:
        return result.totalInstitutes;
      case SearchScope.instructors:
        return result.totalInstructors;
    }
  }

  static const _typeScopes = [SearchScope.courses, SearchScope.institutes, SearchScope.instructors];

  void _updateScopeCounts(SearchScope scope, SearchResult scoped, {SearchResult? all, required bool keyChanged}) {
    // نص أو فلاتر جديدة: أعداد البحث السابق لم تعد صحيحة حتى لو فشل طلب «الكل».
    final next = keyChanged ? <SearchScope, int>{} : Map<SearchScope, int>.of(scopeCounts);
    if (all != null) {
      for (final type in _typeScopes) {
        next[type] = _countIn(all, type);
      }
    }
    if (scope == SearchScope.all) {
      for (final type in _typeScopes) {
        next[type] = _countIn(scoped, type);
      }
    } else {
      next[scope] = _countIn(scoped, scope);
    }
    next.remove(SearchScope.all);
    if (_typeScopes.every(next.containsKey)) {
      next[SearchScope.all] = _typeScopes.fold(0, (sum, type) => sum + next[type]!);
    }
    scopeCounts.assignAll(next);
  }

  void _clearResults() {
    courses.clear();
    institutes.clear();
    instructors.clear();
    totalCourses.value = 0;
    totalInstitutes.value = 0;
    totalInstructors.value = 0;
    scopeCounts.clear();
    _countsKey = null;
  }

  Future<void> clearRecentSearches() => _recentStorage.clear();

  Future<void> submitSearch() async {
    queryText.value = queryController.text;
    await runSearch(resetPage: true, saveRecent: true);
  }

  void applyFilters({int? cityId, int? categoryId, String? level, String? studyType}) {
    selectedCityId.value = cityId;
    selectedCategoryId.value = categoryId;
    selectedLevel.value = level ?? '';
    selectedStudyType.value = studyType ?? '';
    runSearch(resetPage: true, saveRecent: queryController.text.trim().isNotEmpty);
  }

  void clearFilters() {
    selectedCityId.value = null;
    selectedCategoryId.value = null;
    selectedLevel.value = '';
    selectedStudyType.value = '';
    runSearch(resetPage: true, saveRecent: false);
  }

  /// يزيل فلتراً واحداً (زر ✕ في شريط الفلاتر النشطة) ويعيد البحث.
  void removeFilter(SearchFilterKind kind) {
    switch (kind) {
      case SearchFilterKind.category:
        selectedCategoryId.value = null;
      case SearchFilterKind.city:
        selectedCityId.value = null;
      case SearchFilterKind.level:
        selectedLevel.value = '';
      case SearchFilterKind.studyType:
        selectedStudyType.value = '';
    }
    runSearch(resetPage: true, saveRecent: false);
  }

  /// يحدّث [previewCount] لمسودة ورقة الفلاتر — بتأخير قصير كي لا يُرسل طلب مع كل نقرة.
  void previewFilters(SearchFilters draft) {
    _previewDebounce?.cancel();
    final text = queryController.text.trim();
    if (text.isEmpty && draft.isEmpty) {
      _resetPreview();
      return;
    }
    // المسودة = المطبّق: العدد معروف من آخر بحث، بلا طلب جديد.
    final known = draft == appliedFilters && !isSearching.value ? countFor(selectedScope.value) : null;
    if (known != null) {
      _resetPreview(count: known);
      return;
    }
    beginLoad('preview');
    isPreviewing.value = true;
    _previewDebounce = Timer(const Duration(milliseconds: 300), () => _runPreview(text, draft));
  }

  Future<void> _runPreview(String text, SearchFilters draft) async {
    final session = beginLoad('preview');
    final scope = selectedScope.value;
    try {
      final result = await _search(text, scope, draft);
      applyIfCurrent(session, () => previewCount.value = _countIn(result, scope));
    } on ApiCancelledException {
      return;
    } catch (_) {
      if (shouldApply(session)) previewCount.value = null;
    } finally {
      applyIfCurrent(session, () => isPreviewing.value = false);
    }
  }

  /// عند إغلاق الورقة: يُهمل أي عدّ جارٍ.
  void cancelPreview() => _resetPreview();

  void _resetPreview({int? count}) {
    _previewDebounce?.cancel();
    beginLoad('preview');
    isPreviewing.value = false;
    previewCount.value = count;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _previewDebounce?.cancel();
    queryController.removeListener(_onQueryChanged);
    queryController.dispose();
    super.onClose();
  }
}
