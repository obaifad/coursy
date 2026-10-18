import '../../../core/navigation/route_settle.dart';
import '../../../core/cache/memory_cache.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/course_repository.dart';
import '../../../core/data/repositories/enrollment_repository.dart';
import '../../../core/data/repositories/review_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/course_rating_service.dart';
import '../../../core/services/student_id_resolver.dart';
import '../../../core/session/course_catalog_sync.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/auth_guard.dart';
import '../../profile/controllers/my_courses_controller.dart';
import '../../../core/utils/app_toast.dart';

class CourseDetailsController extends GetxController {
  /// صفحات تفاصيل الدورات المفتوحة الآن — لكلٍّ متحكّمها بوسمٍ خاص، فلا يصلح Get.find بدون وسم.
  static final Set<CourseDetailsController> _open = {};
  static List<CourseDetailsController> get open => List.of(_open);

  final CourseRepository _courseRepository = Get.find();
  final ReviewRepository _reviewRepository = Get.find();
  final EnrollmentRepository _enrollmentRepository = Get.find();
  final FavoritesService _favoritesService = Get.find();
  final StudentIdResolver _studentIdResolver = Get.find();
  final TokenStorage _tokenStorage = Get.find();
  final CourseRatingService _ratingService = Get.find();

  final isLoading = false.obs;

  /// true عند فشل جلب الدورة ولا توجد بيانات أولية لعرضها (فتح من إشعار/معرّف فقط).
  final loadFailed = false.obs;
  int? _requestedId;
  final course = Rxn<CourseModel>();
  final schedules = <ScheduleModel>[].obs;
  final reviews = <ReviewModel>[].obs;
  final isEnrolled = false.obs;
  final hasCourseEnrollment = false.obs;

  /// false حتى تُعرف حالة التسجيل (من الذاكرة المؤقتة أو الخادم) — الزر لا يعرض حالة مؤقتة خاطئة.
  final enrollmentResolved = false.obs;
  final hasSubmittedReview = false.obs;
  final isCheckingEnrollment = false.obs;
  final isSubmittingReview = false.obs;

  final courseRating = 5.obs;
  final reviewCommentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _open.add(this);
    final arg = Get.arguments;
    if (arg is CourseModel) {
      _seedEnrollmentFromCache(arg.id);
      course.value = arg;
      schedules.assignAll(arg.schedules);
      _openWithCache(arg.id, hadSeed: true);
    } else if (arg is int) {
      _seedEnrollmentFromCache(arg);
      _openWithCache(arg, hadSeed: false);
    } else {
      loadFailed.value = true;
    }
    if (_tokenStorage.isLoggedIn) {
      // مع مدة الصلاحية (دقيقتان) بدل فرض المزامنة عند كل فتح لصفحة دورة — وبعد حركة الفتح.
      _afterOpening(() => unawaited(_favoritesService.syncFromApi()));
    }
  }

  /// الدورة التي زرناها قبل قليل (تفاصيلها وجداولها وتقييماتها) تظهر كاملة فوراً؛ الطازجة بلا طلب،
  /// والقديمة تُحدَّث بصمت. المقاعد والأسعار تتغيّر، لذلك مدة الصلاحية قصيرة ([_detailsTtl]).
  ///
  /// الطلبات تبدأ بعد انتهاء حركة الفتح ([RouteSettle]): ردّ يصل أثناء الحركة كان يعيد بناء الصفحة
  /// كلها وهي تتحرك. ما لدينا (بيانات البطاقة أو الذاكرة) يُعرض فوراً، وبلا بيانات يظهر الهيكل فوراً.
  void _openWithCache(int id, {required bool hadSeed}) {
    if (id > 0) _requestedId = id;
    final cached = id > 0 ? MemoryCache.get<_CourseSnapshot>(MemoryCache.key('course-details', [id])) : null;
    if (cached == null) {
      if (!hadSeed && id > 0) isLoading.value = true;
      _afterOpening(() => _loadDetails(id, hadSeed: hadSeed));
      return;
    }
    final s = cached.value;
    _requestedId = id;
    loadFailed.value = false;
    course.value = hadSeed ? _mergeCourseDetails(course.value, s.course, hadSeed: true) : s.course;
    schedules.assignAll(s.schedules);
    reviews.assignAll(s.reviews);
    if (cached.isFresh(_detailsTtl)) {
      // حالة التسجيل والتقييم الخاصان بالمستخدم يُجلبان دائماً.
      _afterOpening(() => unawaited(_loadSecondaryData(id)));
    } else {
      _afterOpening(() => _loadDetails(id, hadSeed: true));
    }
  }

  /// بعد حركة فتح الصفحة، وليس إن أُغلقت قبلها.
  void _afterOpening(void Function() work) => RouteSettle.run(() {
    if (!isClosed) work();
  });

  static const Duration _detailsTtl = Duration(minutes: 2);

  void _rememberDetails() {
    final current = course.value;
    if (current == null) return;
    MemoryCache.put<_CourseSnapshot>(
      MemoryCache.key('course-details', [current.id]),
      _CourseSnapshot(course: current, schedules: List.of(schedules), reviews: List.of(reviews)),
    );
  }

  /// سحب للتحديث: يعيد جلب الدورة والجداول والتقييمات (مقاعد وأسعار تتغيّر) دون هيكل تحميل كامل.
  Future<void> refreshDetails() async {
    final id = _requestedId;
    if (id == null) return;
    await _loadDetails(id, hadSeed: true);
    if (_tokenStorage.isLoggedIn) await refreshEnrollment();
  }

  /// إعادة محاولة جلب الدورة بعد فشل التحميل.
  Future<void> retryLoad() async {
    final id = _requestedId;
    if (id == null) return;
    await _loadDetails(id);
  }

  bool get isLoggedIn => _tokenStorage.isLoggedIn;

  bool get isFavorite {
    final id = course.value?.id;
    if (id == null) return false;
    return _favoritesService.isCourseFavorite(id);
  }

  CourseModel _mergeCourseDetails(CourseModel? previous, CourseModel details, {bool hadSeed = false}) {
    if (previous == null) return details;
    final merged = details.copyWith(
      imageUrl: (details.imageUrl?.isNotEmpty ?? false) ? details.imageUrl : previous.imageUrl,
      schedules: details.schedules.isNotEmpty ? details.schedules : previous.schedules,
      instructor: details.instructor ?? previous.instructor,
      categoryName: details.categoryName ?? previous.categoryName,
      description: details.description ?? previous.description,
      requirements: details.requirements ?? previous.requirements,
      instituteCityAr: details.instituteCityAr.isNotEmpty ? details.instituteCityAr : previous.instituteCityAr,
      instituteCityEn: details.instituteCityEn.isNotEmpty ? details.instituteCityEn : previous.instituteCityEn,
      instituteAddress: details.instituteAddress ?? previous.instituteAddress,
      institutePhone: details.institutePhone ?? previous.institutePhone,
      instituteWhatsapp: details.instituteWhatsapp ?? previous.instituteWhatsapp,
      instituteWebsite: details.instituteWebsite ?? previous.instituteWebsite,
      rating: details.rating > 0 || details.reviewsCount != null ? details.rating : previous.rating,
    );
    if (!hadSeed) return merged;
    // القائمة (Home/Courses) غالباً أحدث من /courses/{id} — لا نستبدل العدد بقيمة أقدم.
    return merged.copyWith(
      studentsCount: _preferStudentCount(previous.studentsCount, merged.studentsCount),
      confirmedStudentsCount: _preferStudentCount(previous.confirmedStudentsCount, merged.confirmedStudentsCount),
    );
  }

  int? _preferStudentCount(int? seed, int? fromApi) {
    if (seed == null) return fromApi;
    if (fromApi == null) return seed;
    return fromApi >= seed ? fromApi : seed;
  }

  Future<void> _loadDetails(int id, {bool hadSeed = false}) async {
    if (id <= 0) {
      loadFailed.value = true;
      return;
    }
    _requestedId = id;
    loadFailed.value = false;
    if (!hadSeed) isLoading.value = true;
    try {
      final previous = course.value;
      final results = await Future.wait<Object>([
        _courseRepository.fetchCourseById(id),
        _courseRepository.fetchCourseSchedules(id).catchError((_) => <ScheduleModel>[]),
        _reviewRepository.fetchReviews(courseId: id).catchError((_) => <ReviewModel>[]),
      ]);

      final details = results[0] as CourseModel;
      final apiSchedules = results[1] as List<ScheduleModel>;
      final fetchedReviews = results[2] as List<ReviewModel>;

      course.value = _mergeCourseDetails(previous, details, hadSeed: hadSeed);
      schedules.assignAll(apiSchedules.isNotEmpty ? apiSchedules : details.schedules);
      reviews.assignAll(fetchedReviews);
      if (reviews.isNotEmpty && course.value != null) {
        final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        if (avg > 0) {
          course.value = course.value!.copyWith(rating: avg);
        }
      }
      _rememberDetails();
    } catch (_) {
      // الإبقاء على بيانات القائمة؛ بدونها نعرض حالة فشل مع إعادة محاولة.
      if (course.value == null) loadFailed.value = true;
    } finally {
      isLoading.value = false;
    }

    unawaited(_loadSecondaryData(id));
  }

  Future<void> _loadSecondaryData(int id) async {
    await Future.wait<void>([_updateReviewPermission(), _checkEnrollment(id)]);
  }

  Future<void> refreshEnrollment() async {
    final id = course.value?.id;
    if (id == null) return;
    await Future.wait<void>([_checkEnrollment(id), _refreshStudentCounts(id)]);
  }

  /// أعداد الطلاب من `/courses/{id}` نفسها — بدون تنزيل تسجيلات كل الطلاب.
  Future<void> _refreshStudentCounts(int courseId) async {
    if (course.value == null || courseId <= 0) return;
    try {
      final fresh = await _courseRepository.fetchCourseById(courseId);
      final current = course.value;
      if (current == null || current.id != courseId) return;
      course.value = current.copyWith(
        studentsCount: fresh.studentsCount ?? current.studentsCount,
        confirmedStudentsCount: fresh.confirmedStudentsCount ?? current.confirmedStudentsCount,
      );
    } catch (_) {
      // نُبقي الأعداد الحالية.
    }
  }

  /// يملأ حالة الزر فوراً من قائمة "دوراتي" المحمّلة سابقاً، فلا يظهر وميض قبل رد الخادم.
  void _seedEnrollmentFromCache(int courseId) {
    if (!_tokenStorage.isLoggedIn) {
      enrollmentResolved.value = true;
      return;
    }
    if (!Get.isRegistered<MyCoursesController>()) return;
    final mine = Get.find<MyCoursesController>();
    if (mine.isInitialLoad) return;
    hasCourseEnrollment.value = mine.enrollments.any(
      (e) => e.courseId == courseId && !{'cancelled', 'rejected'}.contains(e.status.toLowerCase()),
    );
    enrollmentResolved.value = true;
  }

  Future<void> _checkEnrollment(int courseId) async {
    if (!_tokenStorage.isLoggedIn) {
      isEnrolled.value = false;
      hasCourseEnrollment.value = false;
      enrollmentResolved.value = true;
      return;
    }
    isCheckingEnrollment.value = true;
    try {
      final list = await _enrollmentRepository.fetchEnrollments();
      var enrolled = false;
      var canReview = false;
      for (final e in list) {
        if (e.courseId != courseId) continue;
        final status = e.status.toLowerCase();
        if (!{'cancelled', 'rejected'}.contains(status)) enrolled = true;
        if (e.allowsReview) canReview = true;
      }
      hasCourseEnrollment.value = enrolled;
      isEnrolled.value = canReview;
    } catch (_) {
      // نُبقي آخر حالة معروفة بدل تصفيرها (تفادياً لوميض زر "احجز الآن").
      if (!enrollmentResolved.value) {
        isEnrolled.value = false;
        hasCourseEnrollment.value = false;
      }
    } finally {
      enrollmentResolved.value = true;
      isCheckingEnrollment.value = false;
    }
  }

  Future<void> toggleFavorite() async {
    final id = course.value?.id;
    if (id == null) return;
    await _favoritesService.toggleCourse(id);
  }

  Future<void> submitReviews() async {
    final item = course.value;
    if (item == null || isSubmittingReview.value) return;
    // القفل قبل أي انتظار: التحقق من الدخول وصلاحية التقييم قد يطلب الخادم، وضغطة ثانية خلاله
    // كانت ترسل تقييماً ثانياً.
    isSubmittingReview.value = true;
    try {
      if (!await AuthGuard.requireLogin(message: 'review_login_required'.tr)) return;

      if (!isEnrolled.value) {
        AppToast.show(
          'alert'.tr,
          hasCourseEnrollment.value ? 'review_completed_required'.tr : 'review_enrollment_required'.tr,
        );
        return;
      }
      await _updateReviewPermission();
      if (hasSubmittedReview.value) {
        AppToast.show('alert'.tr, 'review_once_only'.tr);
        return;
      }

      await _reviewRepository.submitReview(
        courseId: item.id,
        rating: courseRating.value,
        comment: reviewCommentController.text,
      );

      reviews.assignAll(await _reviewRepository.fetchReviews(courseId: item.id));
      _ratingService.invalidateCache();
      if (reviews.isNotEmpty && course.value != null) {
        final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        if (avg > 0) {
          course.value = course.value!.copyWith(rating: avg);
        }
      }
      await _updateReviewPermission();
      reviewCommentController.clear();
      AppToast.show('review_submitted_title'.tr, 'review_submitted_msg'.tr, kind: ToastKind.success);
    } on ApiException catch (e) {
      AppToast.show('error'.tr, e.message);
    } catch (_) {
      AppToast.show('error'.tr, 'review_submit_failed'.tr);
    } finally {
      isSubmittingReview.value = false;
    }
  }

  @override
  void onClose() {
    _open.remove(this);
    final latest = course.value;
    if (latest != null) {
      CourseCatalogSync.patchCourse(latest);
    }
    reviewCommentController.dispose();
    super.onClose();
  }

  Future<void> _updateReviewPermission() async {
    if (!_tokenStorage.isLoggedIn) {
      hasSubmittedReview.value = false;
      return;
    }
    try {
      // التقييم يخزّن users.id في student_id، لا معرّف ملف الطالب.
      final userId = await _studentIdResolver.resolveUserId();
      hasSubmittedReview.value = userId != null && reviews.any((review) => review.studentId == userId);
    } catch (_) {
      hasSubmittedReview.value = false;
    }
  }
}

/// ما يُحفظ لصفحة دورة: الدورة بعد دمج التفاصيل + جداولها + تقييماتها.
class _CourseSnapshot {
  _CourseSnapshot({required this.course, required this.schedules, required this.reviews});

  final CourseModel course;
  final List<ScheduleModel> schedules;
  final List<ReviewModel> reviews;
}
