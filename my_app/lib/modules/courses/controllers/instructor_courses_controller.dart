import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/models/app_models.dart';

class InstructorCoursesController extends GetxController {
  final InstructorRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final courses = <CourseModel>[].obs;
  final instructorName = ''.obs;
  final specialization = RxnString();
  final experienceYears = 0.obs;
  final bio = RxnString();
  final totalCourses = 0.obs;

  late final int instructorId;
  int _page = 1;
  static const _perPage = 12;

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    loadCourses();
  }

  void _readArguments(dynamic arg) {
    if (arg is InstructorModel) {
      instructorId = arg.id;
      instructorName.value = arg.name;
      specialization.value = arg.specialization;
      experienceYears.value = arg.experienceYears;
      bio.value = arg.bio;
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
    isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value || instructorId <= 0) return;
    isLoadingMore.value = true;
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
    } finally {
      isLoadingMore.value = false;
    }
  }
}
