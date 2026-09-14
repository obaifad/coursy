import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/data/repositories/home_repository.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/data/repositories/institute_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/course_rating_service.dart';
import '../../../core/storage/token_storage.dart';

class HomeController extends GetxController with LatestLoadGuard {
  HomeController(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final HomeRepository _homeRepository = Get.find();
  final CourseRepository _courseRepository = Get.find();
  final InstituteRepository _instituteRepository = Get.find();
  final InstructorRepository _instructorRepository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();
  final CourseRatingService _ratingService = Get.find();

  static const int _suggestedLimit = 10;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final errorMessage = RxnString();

  final courses = <CourseModel>[].obs;
  final suggestedCourses = <CourseModel>[].obs;
  final institutes = <InstituteModel>[].obs;
  final privateInstructors = <InstructorModel>[].obs;
  final instructorSubjects = <InstructorSubjectModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final cities = <CityModel>[].obs;

  /// يُزاد عند العودة للرئيسية لإعادة ضبط القوائم الأفقية من نقطة الصفر.
  final horizontalScrollReset = 0.obs;

  /// التمرير العمودي للرئيسية — بدون PageStorage حتى لا يُستعاد موضع قديم.
  final ScrollController scrollController = ScrollController(keepScrollOffset: false);

  bool get isLoggedIn => _tokenStorage.isLoggedIn;

  /// يعيد الرئيسية لأعلى الصفحة (عمودي + أفقي).
  void resetScrollPosition() {
    horizontalScrollReset.value++;
    _scheduleScrollToTop();
  }

  void _scheduleScrollToTop() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _jumpScrollToTop();
      // إطار إضافي بعد انتقالات GetX / IndexedStack.
      SchedulerBinding.instance.addPostFrameCallback((_) => _jumpScrollToTop());
    });
  }

  void _jumpScrollToTop() {
    if (!scrollController.hasClients) return;
    for (final position in scrollController.positions) {
      if ((position.pixels - position.minScrollExtent).abs() > 0.5) {
        position.jumpTo(position.minScrollExtent);
      }
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }

  Future<void> reloadLocalizedData() => loadHome(forceRefresh: true);

  Future<void> loadHome({bool forceRefresh = false}) async {
    final session = beginLoad();

    if (!isLoading.value && !isRefreshing.value) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = null;

    final errors = <String>[];

    try {
      try {
        final homepage = await _homeRepository.fetchHomepage();
        if (!shouldApply(session)) return;
        if (homepage != null) {
          _replaceIfNotEmpty(categories, homepage.categories, session);
          if (!forceRefresh) {
            _replaceIfNotEmpty(courses, await _ratingService.enrich(homepage.courses), session);
            if (!shouldApply(session)) return;
            if (!isLoggedIn) {
              _replaceIfNotEmpty(
                suggestedCourses,
                await _ratingService.enrich(homepage.suggestedCourses),
                session,
              );
            }
          }
          if (!shouldApply(session)) return;
          _replaceIfNotEmpty(institutes, homepage.institutes, session);
          _replaceIfNotEmpty(cities, homepage.cities, session);
        }
      } on ApiCancelledException {
        return;
      } catch (_) {
        // /homepage اختياري — نكمل بجلب القوائم المنفصلة
      }

      if (!shouldApply(session)) return;

      await Future.wait([
        _fetchCategories(errors, session),
        _fetchCourses(errors, session, force: forceRefresh),
        _fetchInstitutes(errors, session, force: forceRefresh),
        _fetchPrivateInstructors(errors, session, force: forceRefresh),
        _fetchInstructorSubjects(errors, session, force: forceRefresh),
      ]);

      if (!shouldApply(session)) return;

      await _fetchSuggestedCourses(errors, session, force: forceRefresh);

      if (!shouldApply(session)) return;

      if (categories.isEmpty && courses.isEmpty && institutes.isEmpty && errors.isNotEmpty) {
        errorMessage.value = errors.first;
      } else if (errors.isNotEmpty) {
        errorMessage.value = 'home_partial_load_error'.tr;
      }
    } on ApiCancelledException {
      return;
    } finally {
      applyIfCurrent(session, () {
        isLoading.value = false;
        isRefreshing.value = false;
      });
    }
  }

  void _replaceIfNotEmpty<T>(RxList<T> target, List<T> source, LoadSession session) {
    if (!shouldApply(session) || source.isEmpty) return;
    target.value = List<T>.from(source);
  }

  Future<void> _fetchCategories(List<String> errors, LoadSession session) async {
    try {
      final fresh = await _categoryRepository.fetchCategories();
      applyIfCurrent(session, () {
        if (fresh.isNotEmpty) {
          categories.value = List<CategoryModel>.from(fresh);
        }
      });
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('categories_load_failed'.tr);
    }
  }

  Future<void> _fetchCourses(List<String> errors, LoadSession session, {bool force = false}) async {
    if (!force && courses.isNotEmpty) return;
    try {
      final fresh = await _courseRepository.fetchCourses();
      if (!shouldApply(session)) return;
      if (fresh.isNotEmpty) {
        final enriched = await _ratingService.enrich(fresh);
        applyIfCurrent(session, () => courses.assignAll(enriched));
      }
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('courses_load_failed'.tr);
    }
  }

  Future<void> _fetchSuggestedCourses(List<String> errors, LoadSession session, {bool force = false}) async {
    try {
      if (isLoggedIn) {
        final personalized = await _courseRepository.fetchSuggestedCourses(limit: _suggestedLimit);
        if (!shouldApply(session)) return;
        suggestedCourses.assignAll(personalized);
        if (personalized.isNotEmpty) return;
      } else if (!force && suggestedCourses.isNotEmpty) {
        return;
      }

      final fallback = _buildSuggestedFallback();
      applyIfCurrent(session, () {
        if (fallback.isNotEmpty) {
          suggestedCourses.value = List<CourseModel>.from(fallback);
        }
      });
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      if (isLoggedIn) errors.add(e.message);
      if (shouldApply(session)) _applySuggestedFallbackIfEmpty();
    } catch (_) {
      if (isLoggedIn) errors.add('suggested_courses_load_failed'.tr);
      if (shouldApply(session)) _applySuggestedFallbackIfEmpty();
    }
  }

  List<CourseModel> _buildSuggestedFallback() {
    if (courses.isEmpty) return const [];

    final featured = courses.where((course) => course.isFeatured).take(_suggestedLimit).toList();
    if (featured.length >= _suggestedLimit) return featured;

    final seen = featured.map((course) => course.id).toSet();
    final toppedUp = <CourseModel>[...featured];
    for (final course in courses) {
      if (toppedUp.length >= _suggestedLimit) break;
      if (seen.add(course.id)) toppedUp.add(course);
    }
    return toppedUp;
  }

  void _applySuggestedFallbackIfEmpty() {
    if (suggestedCourses.isNotEmpty) return;
    final fallback = _buildSuggestedFallback();
    if (fallback.isNotEmpty) {
      suggestedCourses.value = List<CourseModel>.from(fallback);
    }
  }

  Future<void> _fetchInstitutes(List<String> errors, LoadSession session, {bool force = false}) async {
    if (!force && institutes.isNotEmpty) return;
    try {
      final fresh = await _instituteRepository.fetchInstitutes();
      _replaceIfNotEmpty(institutes, fresh, session);
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('institutes_load_failed'.tr);
    }
  }

  Future<void> _fetchPrivateInstructors(List<String> errors, LoadSession session, {bool force = false}) async {
    if (!force && privateInstructors.isNotEmpty) return;
    try {
      final result = await _instructorRepository.fetchInstructorsPage(
        page: 1,
        perPage: 12,
        isPrivate: true,
      );
      applyIfCurrent(session, () {
        if (result.items.isNotEmpty) {
          privateInstructors.value = List<InstructorModel>.from(result.items);
        }
      });
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('private_instructors_load_failed'.tr);
    }
  }

  Future<void> _fetchInstructorSubjects(List<String> errors, LoadSession session, {bool force = false}) async {
    if (!force && instructorSubjects.isNotEmpty) return;
    try {
      final fresh = await _instructorRepository.fetchInstructorSubjectFilters();
      applyIfCurrent(session, () {
        if (fresh.isNotEmpty) {
          instructorSubjects.value = List<InstructorSubjectModel>.from(fresh);
        }
      });
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('instructor_subjects_load_failed'.tr);
    }
  }
}
