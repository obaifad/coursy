import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/network/api_exception.dart';

class CategoryCoursesController extends GetxController with InitialLoadState, SettledLoad {
  final CourseRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final loadMoreFailed = false.obs;
  final courses = <CourseModel>[].obs;
  final selectedSort = CourseSortOption.newest.obs;
  final title = ''.obs;
  final errorMessage = RxnString();

  List<CourseModel> get sortedCourses => sortCourses(courses, selectedSort.value);

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

  String get _cacheKey => MemoryCache.key('category-courses', [categoryId]);

  void _restore(PagedSnapshot<CourseModel> snapshot) {
    courses.assignAll(snapshot.items);
    hasMore.value = snapshot.hasMore;
    _page = snapshot.page;
    isLoading.value = false;
    markLoaded();
  }

  void _remember() => MemoryCache.put<PagedSnapshot<CourseModel>>(
    _cacheKey,
    PagedSnapshot<CourseModel>(items: courses, hasMore: hasMore.value, page: _page),
  );

  void selectSort(CourseSortOption sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
  }

  Future<void> loadCourses() async {
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchCoursesPage(
        page: _page,
        perPage: _perPage,
        query: {'category_id': categoryId},
      );
      courses.assignAll(result.items);
      hasMore.value = result.hasMore;
      markLoaded();
      _remember();
    } catch (e) {
      if (courses.isEmpty) errorMessage.value = userErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchCoursesPage(
        page: nextPage,
        perPage: _perPage,
        query: {'category_id': categoryId},
      );
      courses.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
      _remember();
    } catch (_) {
      loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
