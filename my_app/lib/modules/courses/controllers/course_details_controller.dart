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
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/auth_guard.dart';

class CourseDetailsController extends GetxController {
  final CourseRepository _courseRepository = Get.find();
  final ReviewRepository _reviewRepository = Get.find();
  final EnrollmentRepository _enrollmentRepository = Get.find();
  final FavoritesService _favoritesService = Get.find();
  final StudentIdResolver _studentIdResolver = Get.find();
  final TokenStorage _tokenStorage = Get.find();
  final CourseRatingService _ratingService = Get.find();

  final isLoading = false.obs;
  final course = Rxn<CourseModel>();
  final schedules = <ScheduleModel>[].obs;
  final reviews = <ReviewModel>[].obs;
  final isEnrolled = false.obs;
  final hasCourseEnrollment = false.obs;
  final hasSubmittedReview = false.obs;
  final isCheckingEnrollment = false.obs;
  final isSubmittingReview = false.obs;

  final courseRating = 5.obs;
  final instituteRating = 5.obs;
  final instructorRating = 5.obs;
  final reviewCommentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is CourseModel) {
      course.value = arg;
      schedules.assignAll(arg.schedules);
      _loadDetails(arg.id, hadSeed: true);
    } else if (arg is int) {
      _loadDetails(arg);
    }
    if (_tokenStorage.isLoggedIn) {
      unawaited(_favoritesService.syncFromApi());
    }
  }

  bool get isLoggedIn => _tokenStorage.isLoggedIn;

  bool get isFavorite {
    final id = course.value?.id;
    if (id == null) return false;
    return _favoritesService.isCourseFavorite(id);
  }

  CourseModel _mergeCourseDetails(CourseModel? previous, CourseModel details) {
    if (previous == null) return details;
    return details.copyWith(
      imageUrl: (details.imageUrl?.isNotEmpty ?? false) ? details.imageUrl : previous.imageUrl,
      schedules: details.schedules.isNotEmpty ? details.schedules : previous.schedules,
      instructor: details.instructor ?? previous.instructor,
      categoryName: details.categoryName ?? previous.categoryName,
      description: details.description ?? previous.description,
      requirements: details.requirements ?? previous.requirements,
      instituteCity: details.instituteCity ?? previous.instituteCity,
      instituteAddress: details.instituteAddress ?? previous.instituteAddress,
      institutePhone: details.institutePhone ?? previous.institutePhone,
      instituteWhatsapp: details.instituteWhatsapp ?? previous.instituteWhatsapp,
      instituteWebsite: details.instituteWebsite ?? previous.instituteWebsite,
      rating: details.rating > 0 ? details.rating : previous.rating,
    );
  }

  Future<void> _loadDetails(int id, {bool hadSeed = false}) async {
    if (id <= 0) return;
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

      course.value = _mergeCourseDetails(previous, details);
      schedules.assignAll(apiSchedules.isNotEmpty ? apiSchedules : details.schedules);
      reviews.assignAll(fetchedReviews);
      if (reviews.isNotEmpty && course.value != null) {
        final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        if (avg > 0) {
          course.value = course.value!.copyWith(rating: avg);
        }
      }
    } catch (_) {
      // الإبقاء على بيانات القائمة
    } finally {
      isLoading.value = false;
    }

    unawaited(_loadSecondaryData(id));
  }

  Future<void> _loadSecondaryData(int id) async {
    await Future.wait<void>([
      _enrichConfirmedEnrollmentCount(id),
      _updateReviewPermission(),
      _checkEnrollment(id),
    ]);
  }

  Future<void> refreshEnrollment() async {
    final id = course.value?.id;
    if (id != null) await _checkEnrollment(id);
  }

  Future<void> _enrichConfirmedEnrollmentCount(int courseId) async {
    final item = course.value;
    if (item == null || item.confirmedStudentsCount != null) return;
    final count = await _enrollmentRepository.countConfirmedEnrollmentsForCourse(courseId);
    if (count != null && course.value?.id == courseId) {
      course.value = course.value!.copyWith(confirmedStudentsCount: count);
    }
  }

  Future<void> _checkEnrollment(int courseId) async {
    if (!_tokenStorage.isLoggedIn) {
      isEnrolled.value = false;
      hasCourseEnrollment.value = false;
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
      isEnrolled.value = false;
      hasCourseEnrollment.value = false;
    } finally {
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
    if (item == null) return;

    if (!await AuthGuard.requireLogin(message: 'review_login_required'.tr)) return;

    if (!isEnrolled.value) {
      Get.snackbar(
        'alert'.tr,
        hasCourseEnrollment.value ? 'review_completed_required'.tr : 'review_enrollment_required'.tr,
      );
      return;
    }
    await _updateReviewPermission();
    if (hasSubmittedReview.value) {
      Get.snackbar('alert'.tr, 'review_once_only'.tr);
      return;
    }

    isSubmittingReview.value = true;
    try {
      await _reviewRepository.submitReview(
        courseId: item.id,
        rating: courseRating.value,
        comment: reviewCommentController.text,
      );

      if (item.instituteId != null) {
        try {
          await _reviewRepository.submitReview(
            instituteId: item.instituteId,
            rating: instituteRating.value,
            comment: reviewCommentController.text,
          );
        } catch (_) {}
      }

      if (item.instructor != null) {
        try {
          await _reviewRepository.submitReview(
            instructorId: item.instructor!.id,
            rating: instructorRating.value,
            comment: reviewCommentController.text,
          );
        } catch (_) {}
      }

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
      Get.snackbar('review_submitted_title'.tr, 'review_submitted_msg'.tr);
    } on ApiException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (_) {
      Get.snackbar('error'.tr, 'review_submit_failed'.tr);
    } finally {
      isSubmittingReview.value = false;
    }
  }

  @override
  void onClose() {
    reviewCommentController.dispose();
    super.onClose();
  }

  Future<void> _updateReviewPermission() async {
    if (!_tokenStorage.isLoggedIn) {
      hasSubmittedReview.value = false;
      return;
    }
    try {
      final studentId = await _studentIdResolver.resolve();
      hasSubmittedReview.value = reviews.any((review) => review.studentId == studentId);
    } catch (_) {
      hasSubmittedReview.value = false;
    }
  }
}
