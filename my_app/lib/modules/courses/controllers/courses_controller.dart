import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class CoursesController extends GetxController with LatestLoadGuard {
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

  /// القائمة المرتّبة — تُحسب مرة عند تغيّر الدورات أو الترتيب (كانت تُرتّب مرتين لكل بطاقة تُرسم).
  final sortedCourses = <CourseModel>[].obs;

  /// الترتيب على الجهاز يحتاج كل الدورات ليكون صحيحاً — نحمّلها كلها ما دام العدد معقولاً.
  static const _maxCoursesForFullSort = 300;

  late final Worker _sortWorker;

  @override
  void onInit() {
    super.onInit();
    _sortWorker = everAll([courses, selectedSort], (_) => _resort());
    scrollController.addListener(_onScrollNearEnd);
    _loadCategories();
    loadCourses();
  }

  @override
  void onClose() {
    _sortWorker.dispose();
    scrollController.removeListener(_onScrollNearEnd);
    scrollController.dispose();
    super.onClose();
  }

  void _resort() => sortedCourses.assignAll(sortCourses(courses, selectedSort.value));

  bool get _needsFullList =>
      selectedSort.value != CourseSortOption.newest && hasMore.value && totalCount.value <= _maxCoursesForFullSort;

  Future<void> _loadAllRemaining() async {
    while (_needsFullList && !isLoading.value) {
      final before = courses.length;
      await loadMoreCourses();
      if (courses.length == before) break;
    }
  }

  void _onScrollNearEnd() {
    if (!scrollController.hasClients) return;
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

  void selectCategory(int? id) {
    selectedCategoryId.value = id;
    loadCourses();
  }

  void selectSort(CourseSortOption sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
    _loadAllRemaining();
  }

  Future<void> loadCourses() async {
    final session = beginLoad();
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchCoursesPage(
        page: _page,
        perPage: _perPage,
        query: {if (selectedCategoryId.value != null) 'category_id': selectedCategoryId.value},
      );
      applyIfCurrent(session, () {
        courses.assignAll(result.items);
        totalCount.value = result.total;
        hasMore.value = result.hasMore;
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = userErrorMessage(e);
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
    if (shouldApply(session)) await _loadAllRemaining();
  }

  Future<void> loadMoreCourses() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    // إن تغيّر التصنيف أثناء التحميل تُهمل الصفحة القديمة بدل خلطها بالقائمة الجديدة.
    final session = currentLoad();
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchCoursesPage(
        page: nextPage,
        perPage: _perPage,
        query: {if (selectedCategoryId.value != null) 'category_id': selectedCategoryId.value},
      );
      applyIfCurrent(session, () {
        courses.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
      });
    } catch (_) {
      if (shouldApply(session)) hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
