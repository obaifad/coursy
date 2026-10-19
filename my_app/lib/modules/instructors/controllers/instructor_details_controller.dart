import '../../../core/navigation/route_settle.dart';
import '../../../core/cache/memory_cache.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/data/repositories/review_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/favorites_service.dart';

class InstructorDetailsController extends GetxController with SettledLoad {
  final InstructorRepository _instructorRepository = Get.find();
  final ReviewRepository _reviewRepository = Get.find();
  final FavoritesService _favoritesService = Get.find();

  final isLoading = true.obs;
  final isLoadingCourses = true.obs;
  final isLoadingMoreCourses = false.obs;
  final hasMoreCourses = true.obs;
  final loadMoreCoursesFailed = false.obs;
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

  /// نجح تحميل الدورات مرة (أو استُعيدت من الذاكرة): التحديثات التالية صامتة بلا هيكل.
  bool _coursesLoaded = false;
  static const _coursesPerPage = 12;

  Worker? _favoritesWorker;

  @override
  void onInit() {
    super.onInit();
    _readArguments(Get.arguments);
    _favoritesWorker = ever(_favoritesService.items, (_) => _syncFavorite());
    _syncFavorite();
    final cached = _restoreFromCache();
    if (cached != null && cached.isFresh()) return;
    // ما لدينا يُعرض فوراً (كما كان أول loadDetails يفعل)، والطلبات بعد حركة الفتح.
    if (instructorId > 0 && instructor.value != null) isLoading.value = false;
    afterRouteSettles(loadDetails);
  }

  String get _cacheKey => MemoryCache.key('instructor-details', [instructorId]);

  /// آخر ما عُرض للمدرّس (بياناته ودوراته وتقييماته): يُعرض فوراً بلا هياكل عند العودة إليه.
  CacheEntry<_InstructorSnapshot>? _restoreFromCache() {
    if (instructorId <= 0) return null;
    final cached = MemoryCache.get<_InstructorSnapshot>(_cacheKey);
    if (cached == null) return null;
    final s = cached.value;
    instructor.value = s.instructor;
    courses.assignAll(s.courses.items);
    hasMoreCourses.value = s.courses.hasMore;
    totalCourses.value = s.courses.total;
    _coursesPage = s.courses.page;
    reviews.assignAll(s.reviews);
    isLoading.value = false;
    isLoadingCourses.value = false;
    _coursesLoaded = true;
    return cached;
  }

  void _remember() {
    final current = instructor.value;
    if (current == null || instructorId <= 0 || coursesError.value != null) return;
    MemoryCache.put<_InstructorSnapshot>(
      _cacheKey,
      _InstructorSnapshot(
        instructor: current,
        courses: PagedSnapshot<CourseModel>(
          items: courses,
          hasMore: hasMoreCourses.value,
          page: _coursesPage,
          total: totalCourses.value,
        ),
        reviews: List.of(reviews),
      ),
    );
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
      _remember();
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
      // تحديث بصمت (من الذاكرة أو بالسحب): تبقى القائمة الحالية ظاهرة بدل الهيكل.
      if (!_coursesLoaded) isLoadingCourses.value = true;
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
      _coursesLoaded = true;
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
        if (courses.isEmpty) coursesError.value = userErrorMessage(e);
      } else {
        loadMoreCoursesFailed.value = true;
      }
    } finally {
      if (reset) isLoadingCourses.value = false;
    }
  }

  Future<void> retryCourses() => _loadCourses(reset: true);

  Future<void> loadMoreCourses() async {
    if (!hasMoreCourses.value || isLoadingMoreCourses.value || isLoadingCourses.value) return;
    isLoadingMoreCourses.value = true;
    loadMoreCoursesFailed.value = false;
    try {
      await _loadCourses(reset: false);
      _remember();
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

/// ما يُحفظ لصفحة مدرّس: بياناته + صفحات دوراته المحمّلة + تقييماته.
class _InstructorSnapshot {
  _InstructorSnapshot({required this.instructor, required this.courses, required this.reviews});

  final InstructorModel instructor;
  final PagedSnapshot<CourseModel> courses;
  final List<ReviewModel> reviews;
}
