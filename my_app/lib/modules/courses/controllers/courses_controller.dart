import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class CoursesController extends GetxController with LatestLoadGuard, InitialLoadState {
  final CourseRepository _repository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final courses = <CourseModel>[].obs;

  /// العدد الكلي من الـ API (وليس عدد الصفحات المحمّلة حتى الآن).
  final totalCount = 0.obs;
  final categories = <CategoryModel>[].obs;
  final selectedCategoryId = RxnInt();
  final selectedSort = CourseSortOption.newest.obs;
  int _page = 1;
  static const _perPage = 10;

  final ScrollController scrollController = ScrollController();

  /// فشل جلب الصفحة التالية: نُبقي «المزيد» ونعرض «إعادة المحاولة» في آخر القائمة، ونوقف الجلب
  /// التلقائي عند التمرير حتى يضغطها (كانت القائمة تنتهي بصمت كأنه لا توجد دورات أخرى).
  final loadMoreFailed = false.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScrollNearEnd);
    _loadCategories();
    _hydrateFromDisk();
    loadCourses();
  }

  /// بعد إعادة فتح التطبيق: آخر صفحة أولى محفوظة على القرص ([ApiDiskCache]) تُرسم فوراً بلا هيكل، والشبكة
  /// تحدّثها بصمت.
  void _hydrateFromDisk() {
    final cached = _repository.cachedCoursesPage(page: 1, perPage: _perPage, query: _query());
    if (cached == null || cached.items.isEmpty) return;
    courses.assignAll(cached.items);
    totalCount.value = cached.total;
    hasMore.value = cached.hasMore;
    _page = 1;
    isLoading.value = false;
    markLoaded();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScrollNearEnd);
    scrollController.dispose();
    super.onClose();
  }

  /// قائمة جديدة (تصنيف أو ترتيب آخر) تبدأ من أولها، لا من موضع القائمة السابقة.
  void _scrollToTop() {
    if (scrollController.hasClients && scrollController.offset > 0) scrollController.jumpTo(0);
  }

  void _onScrollNearEnd() {
    if (!scrollController.hasClients || loadMoreFailed.value) return;
    final position = scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels < position.maxScrollExtent - 280) return;
    loadMoreCourses();
  }

  Future<void> _loadCategories() async {
    final session = beginLoad('categories');
    try {
      final fresh = await _categoryRepository.fetchCategories();
      applyIfCurrent(session, () => categories.assignAll(fresh));
    } on ApiCancelledException {
      return;
    } catch (_) {
      if (shouldApply(session)) categories.clear();
    }
  }

  Future<void> reloadLocalizedData() async {
    await _loadCategories();
    await loadCourses();
  }

  /// التصنيف والترتيب معاً: لكل تركيبة قائمتها وترقيمها (الترتيب على الخادم، فكل ترتيب قائمة مختلفة).
  String _cacheKey(int? category, CourseSortOption sort) =>
      MemoryCache.key('courses-tab', [category ?? 'all', sort.name]);

  Map<String, dynamic> _query() => {
    if (selectedCategoryId.value != null) 'category_id': selectedCategoryId.value,
    if (selectedSort.value.apiValue != null) 'sort': selectedSort.value.apiValue,
  };

  /// يحفظ ما حُمّل لتصنيف وترتيب ما (العناصر وحالة الترقيم) كي يعود إليه المستخدم فوراً.
  void _remember(int? category, CourseSortOption sort) {
    if (selectedCategoryId.value != category || selectedSort.value != sort) return;
    MemoryCache.put<PagedSnapshot<CourseModel>>(
      _cacheKey(category, sort),
      PagedSnapshot<CourseModel>(items: courses, hasMore: hasMore.value, page: _page, total: totalCount.value),
    );
  }

  /// تبديل التصنيف:
  ///  - المحدد نفسه: لا شيء (كانت كل ضغطة تجلب من الشبكة وتعيد الرسم).
  void selectCategory(int? id) {
    if (selectedCategoryId.value == id) return;
    selectedCategoryId.value = id;
    _showCurrentList();
  }

  /// تبديل الترتيب: الخادم يرتّب، فالقائمة الجديدة تبدأ من صفحتها الأولى (لا تحميل لكل الصفحات).
  void selectSort(CourseSortOption sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
    _showCurrentList();
  }

  /// يعرض قائمة التصنيف والترتيب الحاليين:
  ///  - زرناها قبل قليل: فوراً بلا هيكل؛ تُحدَّث بصمت إن قدمت (3 دقائق).
  ///  - جديدة: تُفرَّغ القائمة فوراً فيظهر الهيكل (كانت القائمة السابقة تبقى حتى يصل الرد، فلا يبدو أن
  ///    الضغطة عملت)، ثم تُجلب.
  void _showCurrentList() {
    _scrollToTop();
    // يُبطل أي رد قادم لقائمة سابقة (طلب الصفحة الأولى أو «المزيد»).
    beginLoad();
    isLoadingMore.value = false;
    loadMoreFailed.value = false;
    errorMessage.value = null;

    final cached = MemoryCache.get<PagedSnapshot<CourseModel>>(_cacheKey(selectedCategoryId.value, selectedSort.value));
    if (cached != null) {
      final snapshot = cached.value;
      courses.assignAll(snapshot.items);
      totalCount.value = snapshot.total;
      hasMore.value = snapshot.hasMore;
      _page = snapshot.page;
      isLoading.value = false;
      markLoaded();
      if (!cached.isFresh()) loadCourses();
      return;
    }
    courses.clear();
    totalCount.value = 0;
    hasMore.value = true;
    resetInitialLoad();
    isLoading.value = true;
    loadCourses();
  }

  Future<void> loadCourses() async {
    final session = beginLoad();
    final category = selectedCategoryId.value;
    final sort = selectedSort.value;
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    loadMoreFailed.value = false;
    _page = 1;
    try {
      final result = await _repository.fetchCoursesPage(page: _page, perPage: _perPage, query: _query());
      applyIfCurrent(session, () {
        courses.assignAll(result.items);
        totalCount.value = result.total;
        hasMore.value = result.hasMore;
        markLoaded();
        _remember(category, sort);
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = userErrorMessage(e);
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMoreCourses() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    // إن تغيّر التصنيف أثناء التحميل تُهمل الصفحة القديمة بدل خلطها بالقائمة الجديدة.
    final session = currentLoad();
    final category = selectedCategoryId.value;
    final sort = selectedSort.value;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchCoursesPage(page: nextPage, perPage: _perPage, query: _query());
      applyIfCurrent(session, () {
        courses.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
        _remember(category, sort);
      });
    } catch (_) {
      if (shouldApply(session)) loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
