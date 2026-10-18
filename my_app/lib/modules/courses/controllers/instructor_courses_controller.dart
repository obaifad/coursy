import '../../../core/cache/memory_cache.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/network/api_exception.dart';

class InstructorCoursesController extends GetxController with InitialLoadState {
  final InstructorRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final loadMoreFailed = false.obs;
  final courses = <CourseModel>[].obs;
  final instructorName = ''.obs;
  final specialization = RxnString();
  final experienceYears = 0.obs;
  final bio = RxnString();
  final gender = RxnString();
  final totalCourses = 0.obs;
  final errorMessage = RxnString();

  late final int instructorId;
  int _page = 1;
  static const _perPage = 12;

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    final cached = instructorId > 0 ? MemoryCache.get<PagedSnapshot<CourseModel>>(_cacheKey) : null;
    if (cached != null) {
      _restore(cached.value);
      if (cached.isFresh()) return;
    }
    loadCourses();
  }

  String get _cacheKey => MemoryCache.key('instructor-courses', [instructorId]);

  void _restore(PagedSnapshot<CourseModel> snapshot) {
    courses.assignAll(snapshot.items);
    hasMore.value = snapshot.hasMore;
    totalCourses.value = snapshot.total;
    _page = snapshot.page;
    isLoading.value = false;
    markLoaded();
  }

  void _remember() => MemoryCache.put<PagedSnapshot<CourseModel>>(
    _cacheKey,
    PagedSnapshot<CourseModel>(items: courses, hasMore: hasMore.value, page: _page, total: totalCourses.value),
  );

  void _readArguments(dynamic arg) {
    if (arg is InstructorModel) {
      instructorId = arg.id;
      instructorName.value = arg.name;
      specialization.value = arg.specializationLabel;
      experienceYears.value = arg.experienceYears;
      bio.value = arg.bio;
      gender.value = arg.gender;
      return;
    }
    if (arg is Map<String, dynamic>) {
      instructorId = (arg['id'] as int?) ?? int.tryParse('${arg['id']}') ?? 0;
      instructorName.value = arg['name']?.toString() ?? '';
      specialization.value = arg['specialization']?.toString();
      experienceYears.value = int.tryParse('${arg['experience_years'] ?? arg['experienceYears'] ?? 0}') ?? 0;
      bio.value = arg['bio']?.toString();
      return;
    }
    instructorId = 0;
    instructorName.value = 'instructor_default'.tr;
  }

  Future<void> loadCourses() async {
    if (instructorId <= 0) {
      isLoading.value = false;
      courses.clear();
      hasMore.value = false;
      return;
    }
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchInstructorCoursesPage(
        instructorId: instructorId,
        page: _page,
        perPage: _perPage,
      );
      courses.assignAll(result.items);
      hasMore.value = result.hasMore;
      totalCourses.value = result.total;
      markLoaded();
      _remember();
    } catch (e) {
      if (courses.isEmpty) errorMessage.value = userErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value || instructorId <= 0) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchInstructorCoursesPage(
        instructorId: instructorId,
        page: nextPage,
        perPage: _perPage,
      );
      courses.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
      totalCourses.value = result.total;
      _remember();
    } catch (_) {
      loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
