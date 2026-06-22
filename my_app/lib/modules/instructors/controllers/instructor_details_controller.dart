import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/data/repositories/review_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/services/favorites_service.dart';

class InstructorDetailsController extends GetxController {
  final InstructorRepository _instructorRepository = Get.find();
  final ReviewRepository _reviewRepository = Get.find();
  final FavoritesService _favoritesService = Get.find();

  final isLoading = true.obs;
  final isLoadingCourses = true.obs;
  final isLoadingMoreCourses = false.obs;
  final hasMoreCourses = true.obs;
  final isFavorite = false.obs;
  final instructor = Rxn<InstructorModel>();
  final courses = <CourseModel>[].obs;
  final reviews = <ReviewModel>[].obs;
  final totalCourses = 0.obs;

  late int instructorId;
  int _coursesPage = 1;
  static const _coursesPerPage = 12;

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    _syncFavorite();
    loadDetails();
  }

  void _readArguments(dynamic arg) {
    if (arg is InstructorModel) {
      instructorId = arg.id;
      instructor.value = arg;
      return;
    }
    if (arg is Map<String, dynamic>) {
      instructorId = JsonHelpers.parseInt(arg['id']);
      if (instructorId > 0) {
        instructor.value = InstructorModel.fromJson(arg);
      }
      return;
    }
    instructorId = 0;
  }

  void _syncFavorite() {
    if (instructorId > 0) {
      isFavorite.value = _favoritesService.isInstructorFavorite(instructorId);
    }
  }

  Future<void> loadDetails() async {
    if (instructorId <= 0) {
      isLoading.value = false;
      isLoadingCourses.value = false;
      return;
    }

    final hasSeed = instructor.value != null;
    isLoading.value = !hasSeed;

    try {
      await Future.wait<void>([
        _refreshInstructor(),
        _loadCourses(reset: true),
        _loadReviews(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshInstructor() async {
    try {
      final fresh = await _instructorRepository.fetchInstructorById(instructorId);
      instructor.value = fresh;
    } catch (_) {
      // الإبقاء على بيانات الكارد
    }
  }

  Future<void> _loadCourses({required bool reset}) async {
    if (instructorId <= 0) {
      isLoadingCourses.value = false;
      return;
    }
    if (reset) {
      isLoadingCourses.value = true;
      _coursesPage = 1;
    }
    try {
      final result = await _instructorRepository.fetchInstructorCoursesPage(
        instructorId: instructorId,
        page: _coursesPage,
        perPage: _coursesPerPage,
      );
      if (reset) {
        courses.assignAll(result.items);
      } else {
        courses.addAll(result.items);
      }
      hasMoreCourses.value = result.hasMore;
      totalCourses.value = result.total;
    } finally {
      if (reset) isLoadingCourses.value = false;
    }
  }

  Future<void> loadMoreCourses() async {
    if (!hasMoreCourses.value || isLoadingMoreCourses.value || isLoadingCourses.value) return;
    isLoadingMoreCourses.value = true;
    try {
      _coursesPage += 1;
      await _loadCourses(reset: false);
    } finally {
      isLoadingMoreCourses.value = false;
    }
  }

  Future<void> _loadReviews() async {
    try {
      reviews.assignAll(await _reviewRepository.fetchReviews(instructorId: instructorId));
    } catch (_) {
      reviews.clear();
    }
  }

  Future<void> toggleFavorite() async {
    if (instructorId <= 0) return;
    final added = await _favoritesService.toggleInstructor(instructorId);
    isFavorite.value = added || _favoritesService.isInstructorFavorite(instructorId);
  }
}
