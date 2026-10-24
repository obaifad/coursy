import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/network/api_exception.dart';

class CategoryCoursesController extends GetxController with LatestLoadGuard, InitialLoadState, SettledLoad {
  final CourseRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final loadMoreFailed = false.obs;
  final courses = <CourseModel>[].obs;
  final selectedSort = CourseSortOption.newest.obs;
  final title = ''.obs;
  final errorMessage = RxnString();

  late final int categoryId;
  int _page = 1;
  static const _perPage = 12;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      categoryId = JsonHelpers.parseInt(arg['id']);
      title.value = arg['name']?.toString() ?? 'category_default_title'.tr;
    } else {
      categoryId = 0;
      title.value = 'category_default_title'.tr;
    }
    final cached = MemoryCache.get<PagedSnapshot<CourseModel>>(_cacheKey);
    if (cached != null) {
      // زيارة سابقة: القائمة فوراً بلا هيكل؛ القديمة فقط تُحدَّث بصمت بعد الحركة.
      _restore(cached.value);
      if (cached.isFresh()) return;
    }
    // الهيكل يظهر أثناء حركة الفتح، والبيانات تُجلب بعدها: لا يتبدّل المحتوى والصفحة تتحرك.
    afterRouteSettles(loadCourses);
  }

  /// الترتيب على الخادم: لكل ترتيب قائمته وترقيمه.
  String get _cacheKey => MemoryCache.key('category-courses', [categoryId, selectedSort.value.name]);

  Map<String, dynamic> get _query => {
    'category_id': categoryId,
    if (selectedSort.value.apiValue != null) 'sort': selectedSort.value.apiValue,
  };

  void _restore(PagedSnapshot<CourseModel> snapshot) {
    courses.assignAll(snapshot.items);
    hasMore.value = snapshot.hasMore;
    _page = snapshot.page;
    isLoading.value = false;
    markLoaded();
  }

  void _remember(CourseSortOption sort) {
    if (selectedSort.value != sort) return;
    MemoryCache.put<PagedSnapshot<CourseModel>>(
      _cacheKey,
      PagedSnapshot<CourseModel>(items: courses, hasMore: hasMore.value, page: _page),
    );
  }

  /// تبديل الترتيب: الخادم يرتّب، فالقائمة الجديدة تبدأ من صفحتها الأولى. زرناها قبل قليل: فوراً؛ وإلا
  /// يظهر الهيكل ثم تُجلب. أي رد قادم لترتيب سابق يُهمل.
  void selectSort(CourseSortOption sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
    beginLoad();
    isLoadingMore.value = false;
    loadMoreFailed.value = false;
    errorMessage.value = null;
    final cached = MemoryCache.get<PagedSnapshot<CourseModel>>(_cacheKey);
    if (cached != null) {
      _restore(cached.value);
      if (!cached.isFresh()) loadCourses();
      return;
    }
    courses.clear();
    hasMore.value = true;
    resetInitialLoad();
    isLoading.value = true;
    loadCourses();
  }

  Future<void> loadCourses() async {
    final session = beginLoad();
    final sort = selectedSort.value;
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchCoursesPage(page: 1, perPage: _perPage, query: _query);
      applyIfCurrent(session, () {
        courses.assignAll(result.items);
        // بعد النجاح فقط: تصفيره قبل الطلب كان يجعل «المزيد» بعد تحديث فاشل يكرّر الصفحة الثانية.
        _page = 1;
        hasMore.value = result.hasMore;
        markLoaded();
        _remember(sort);
      });
    } catch (e) {
      if (shouldApply(session) && courses.isEmpty) errorMessage.value = userErrorMessage(e);
    } finally {
      finishLoad(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    // إن تغيّر الترتيب أثناء التحميل تُهمل الصفحة القديمة بدل خلطها بالقائمة الجديدة.
    final session = currentLoad();
    final sort = selectedSort.value;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchCoursesPage(page: nextPage, perPage: _perPage, query: _query);
      applyIfCurrent(session, () {
        courses.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
        _remember(sort);
      });
    } catch (_) {
      if (shouldApply(session)) loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
