import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/data/repositories/review_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/network/api_exception.dart';
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
  final isLoadingReviews = false.obs;
  final totalCourses = 0.obs;

  /// فشل تحميل الدورات: «تعذّر التحميل» مع إعادة المحاولة بدل «لا دورات».
  final coursesError = RxnString();

  late int instructorId;
  int _coursesPage = 1;
  static const _coursesPerPage = 12;

  Worker? _favoritesWorker;

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    _favoritesWorker = ever(_favoritesService.items, (_) => _syncFavorite());
    _syncFavorite();
    loadDetails();
  }

  @override
  void onClose() {
    _favoritesWorker?.dispose();
    super.onClose();
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
      await Future.wait<void>([_refreshInstructor(), _loadCourses(reset: true), _loadReviews()]);
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
      coursesError.value = null;
    }
    // الصفحة تتقدّم بعد النجاح فقط — كانت تتقدّم قبل الطلب فتُتخطّى صفحة كاملة بعد أي فشل.
    final page = reset ? 1 : _coursesPage + 1;
    try {
      final result = await _instructorRepository.fetchInstructorCoursesPage(
        instructorId: instructorId,
        page: page,
        perPage: _coursesPerPage,
      );
      _coursesPage = page;
      if (reset) {
        courses.assignAll(result.items);
      } else {
        courses.addAll(result.items);
      }
      hasMoreCourses.value = result.hasMore;
      totalCourses.value = result.total;
    } catch (e) {
      // كان الخطأ يخرج من loadDetails بلا معالجة.
      if (reset) {
        coursesError.value = userErrorMessage(e);
      } else {
        Get.snackbar('error'.tr, 'error_load_more_failed'.tr);
      }
    } finally {
      if (reset) isLoadingCourses.value = false;
    }
  }

  Future<void> retryCourses() => _loadCourses(reset: true);

  Future<void> loadMoreCourses() async {
    if (!hasMoreCourses.value || isLoadingMoreCourses.value || isLoadingCourses.value) return;
    isLoadingMoreCourses.value = true;
    try {
      await _loadCourses(reset: false);
    } finally {
      isLoadingMoreCourses.value = false;
    }
  }

  Future<void> _loadReviews() async {
    if (instructorId <= 0) return;
    isLoadingReviews.value = true;
    try {
      reviews.assignAll(await _reviewRepository.fetchReviews(instructorId: instructorId));
    } catch (_) {
      reviews.clear();
    } finally {
      isLoadingReviews.value = false;
    }
  }

  Future<void> toggleFavorite() async {
    if (instructorId <= 0) return;
    await _favoritesService.toggleInstructor(instructorId);
    _syncFavorite();
  }
}
