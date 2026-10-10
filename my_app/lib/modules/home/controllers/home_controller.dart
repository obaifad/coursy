import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/data/repositories/enrollment_repository.dart';
import '../../../core/data/repositories/home_repository.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/data/repositories/institute_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/course_rating_service.dart';
import '../../../core/storage/token_storage.dart';
import '../upcoming_lecture.dart';

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

  /// أقرب محاضرة للطالب المسجّل (تسجيل مؤكد + جدول معروف)؛ null = ضيف أو لا محاضرات قادمة.
  final upcomingLecture = Rxn<UpcomingLecture>();

  /// يُزاد عند العودة للرئيسية لإعادة ضبط القوائم الأفقية من نقطة الصفر.
  final horizontalScrollReset = 0.obs;

  /// التمرير العمودي للرئيسية — بدون PageStorage حتى لا يُستعاد موضع قديم.
  final ScrollController scrollController = ScrollController(keepScrollOffset: false);

  bool get isLoggedIn => _tokenStorage.isLoggedIn;

  static const int _bannerLimit = 5;

  /// دورات بانر الرئيسية (التسجيل المفتوح فقط): المميزة أولاً ثم ذات الخصم ثم الأعلى تقييماً.
  /// تُقرأ داخل Obx فتتحدّث مع [courses]. فارغة = تُعرض بطاقة الترحيب الثابتة بدلها.
  List<CourseModel> get bannerCourses {
    final open = courses.where((course) => course.isRegistrationOpen).toList();
    final featured = open.where((course) => course.isFeatured);
    final discounted = open.where((course) => !course.isFeatured && course.hasDiscount);
    final rest = open.where((course) => !course.isFeatured && !course.hasDiscount).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return [...featured, ...discounted, ...rest].take(_bannerLimit).toList(growable: false);
  }

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

  Future<void> reloadLocalizedData() => loadHome(forceRefresh: true, refreshStatic: true);

  static const _staleAfter = Duration(minutes: 2);
  DateTime? _lastLoadedAt;

  /// إعادة تحميل عند العودة للرئيسية فقط إن مرّ [_staleAfter] على آخر تحميل.
  Future<void> refreshIfStale() {
    final last = _lastLoadedAt;
    if (last != null && DateTime.now().difference(last) < _staleAfter) return Future<void>.value();
    return loadHome(forceRefresh: true);
  }

  /// [forceRefresh]: يعيد جلب الدورات والمعاهد والمدرّسين والمقترحات (بعد الدخول/الخروج/التسجيل...).
  /// [refreshStatic]: يعيد أيضاً جلب القوائم الثابتة (التصنيفات، تخصصات المدرّسين) — عند السحب
  /// للتحديث أو تغيير اللغة فقط؛ لا تتغير بتسجيل الدخول، وجلبها مكلف (عدّ المدرّسين عبر عدة صفحات).
  Future<void> loadHome({bool forceRefresh = false, bool refreshStatic = false}) async {
    final session = beginLoad();
    _lastLoadedAt = DateTime.now();

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
              _replaceIfNotEmpty(suggestedCourses, await _ratingService.enrich(homepage.suggestedCourses), session);
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
        _fetchCategories(errors, session, force: refreshStatic),
        _fetchCourses(errors, session, force: forceRefresh),
        _fetchInstitutes(errors, session, force: forceRefresh),
        _fetchPrivateInstructors(errors, session, force: forceRefresh),
        _fetchInstructorSubjects(errors, session, force: refreshStatic),
        _fetchUpcomingLecture(session),
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
    _setIfChanged(target, source);
  }

  /// بصمة حقول العرض فقط — لمنع إعادة بناء القوائم والصور عندما تأتي نفس البيانات من إعادة التحميل.
  String _sig(Object? o) => switch (o) {
    CourseModel c =>
      '${c.id}|${c.title}|${c.imageUrl}|${c.price}|${c.rating}|${c.studentsCount}|${c.isRegistrationClosed}',
    InstituteModel i => '${i.id}|${i.name}|${i.logoUrl}|${i.coursesCount}|${i.rating}|${i.city}',
    CategoryModel c => '${c.id}|${c.name}|${c.icon}|${c.coursesCount}',
    CityModel c => '${c.id}|${c.name}|${c.institutesCount}|${c.coursesCount}',
    InstructorModel i => '${i.id}|${i.name}|${i.imageUrl}',
    InstructorSubjectModel s => '${s.key}|${s.name}|${s.instructorsCount}',
    _ => '${o.hashCode}',
  };

  /// يستبدل القائمة فقط إن تغيّر محتواها (لا وميض صور عند تحديث بنفس البيانات).
  void _setIfChanged<T>(RxList<T> target, List<T> fresh) {
    if (target.length == fresh.length) {
      var same = true;
      for (var i = 0; i < fresh.length; i++) {
        if (_sig(target[i]) != _sig(fresh[i])) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    target.assignAll(fresh);
  }

  /// غير حرج: فشله لا يُظهر خطأ في الرئيسية — يبقى البانر العادي.
  Future<void> _fetchUpcomingLecture(LoadSession session) async {
    if (!isLoggedIn || !Get.isRegistered<EnrollmentRepository>()) {
      upcomingLecture.value = null;
      return;
    }
    try {
      final enrollments = await Get.find<EnrollmentRepository>().fetchEnrollments();
      final confirmed = enrollments
          .where((e) => UpcomingLecture.isConfirmed(e.status) && e.course != null && e.courseId != null)
          .take(6)
          .toList();
      // جدول الدورة إن جاء مع التسجيل، وإلا من /course-schedules (طلب لكل دورة مؤكدة، 6 كحد أقصى).
      final schedules = <int, List<ScheduleModel>>{};
      await Future.wait(
        confirmed.map((e) async {
          final own = e.course!.schedules;
          schedules[e.id] = own.isNotEmpty
              ? own
              : await _courseRepository.fetchCourseSchedules(e.courseId!).catchError((Object _) => <ScheduleModel>[]);
        }),
      );
      if (!shouldApply(session)) return;
      upcomingLecture.value = UpcomingLecture.find(confirmed, (e) => schedules[e.id] ?? const [], DateTime.now());
    } on ApiCancelledException {
      return;
    } catch (_) {
      // نُبقي آخر قيمة معروفة.
    }
  }

  Future<void> _fetchCategories(List<String> errors, LoadSession session, {bool force = false}) async {
    // /homepage يُرجع التصنيفات غالباً — لا نعيد جلب كل صفحاتها في كل تحميل.
    if (!force && categories.isNotEmpty) return;
    try {
      final fresh = await _categoryRepository.fetchCategories();
      applyIfCurrent(session, () {
        if (fresh.isNotEmpty) {
          _setIfChanged(categories, fresh);
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
        applyIfCurrent(session, () => _setIfChanged(courses, enriched));
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
        _setIfChanged(suggestedCourses, personalized);
        if (personalized.isNotEmpty) return;
      } else if (!force && suggestedCourses.isNotEmpty) {
        return;
      }

      final fallback = _buildSuggestedFallback();
      applyIfCurrent(session, () {
        if (fallback.isNotEmpty) {
          _setIfChanged(suggestedCourses, fallback);
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
      _setIfChanged(suggestedCourses, fallback);
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
      final result = await _instructorRepository.fetchInstructorsPage(page: 1, perPage: 12, isPrivate: true);
      applyIfCurrent(session, () {
        if (result.items.isNotEmpty) {
          _setIfChanged(privateInstructors, result.items);
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
          _setIfChanged(instructorSubjects, fresh);
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
