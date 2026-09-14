import 'package:get/get.dart';

import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/data/repositories/institute_repository.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class InstitutesController extends GetxController with LatestLoadGuard {
  final InstituteRepository _repository = Get.find();
  final CityRepository _cityRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final institutes = <InstituteModel>[].obs;
  final cities = <CityModel>[].obs;
  final selectedCityId = RxnInt();
  int _page = 1;
  static const _perPage = 12;

  @override
  void onInit() {
    super.onInit();
    _loadCities();
    loadInstitutes();
  }

  Future<void> _loadCities() async {
    final session = beginLoad();
    try {
      final fresh = await _cityRepository.fetchCities();
      applyIfCurrent(session, () => cities.assignAll(fresh));
    } on ApiCancelledException {
      return;
    } catch (_) {
      if (shouldApply(session)) cities.clear();
    }
  }

  Future<void> reloadLocalizedData() async {
    await _loadCities();
    await loadInstitutes();
  }

  void selectCity(int? id) {
    selectedCityId.value = id;
    loadInstitutes();
  }

  Future<void> loadInstitutes() async {
    final session = beginLoad();
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchInstitutesPage(
        page: _page,
        perPage: _perPage,
        query: {
          if (selectedCityId.value != null) 'city_id': selectedCityId.value,
        },
      );
      applyIfCurrent(session, () {
        institutes.assignAll(result.items);
        hasMore.value = result.hasMore;
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = e.toString();
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMoreInstitutes() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchInstitutesPage(
        page: nextPage,
        perPage: _perPage,
        query: {
          if (selectedCityId.value != null) 'city_id': selectedCityId.value,
        },
      );
      institutes.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }
}

class InstituteDetailsController extends GetxController {
  final InstituteRepository _instituteRepository = Get.find();
  final CourseRepository _courseRepository = Get.find();
  final InstructorRepository _instructorRepository = Get.find();

  final isLoading = true.obs;
  final institute = Rxn<InstituteModel>();
  final courses = <CourseModel>[].obs;
  final instructors = <InstructorModel>[].obs;

  late final int instituteId;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is InstituteModel) {
      instituteId = arg.id;
      institute.value = arg;
    } else if (arg is int) {
      instituteId = arg;
    } else {
      instituteId = 0;
    }
    loadDetails();
  }

  int get displayedCoursesCount {
    final fromApi = institute.value?.coursesCount ?? 0;
    final loaded = courses.length;
    if (fromApi > 0) return fromApi;
    return loaded;
  }

  Future<void> loadDetails() async {
    final hasSeed = institute.value != null;
    if (!hasSeed) isLoading.value = true;
    try {
      await Future.wait<void>([
        _fetchInstituteDetails(),
        _fetchCourses(),
        _fetchInstructors(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchInstituteDetails() async {
    if (instituteId <= 0) return;
    try {
      final details = await _instituteRepository.fetchInstituteById(instituteId);
      institute.value = _mergeInstitute(institute.value, details);
    } catch (_) {
      // الإبقاء على بيانات الانتقال إن فشل التفاصيل
    }
  }

  Future<void> _fetchCourses() async {
    var instituteCourses = <CourseModel>[];
    try {
      instituteCourses = await _courseRepository.fetchInstituteCourses(instituteId);
    } catch (_) {
      try {
        final all = await _courseRepository.fetchCourses(query: {'institute_id': instituteId});
        instituteCourses = all.where((c) => c.instituteId == instituteId).toList();
      } catch (_) {
        instituteCourses = [];
      }
    }
    courses.assignAll(instituteCourses);
    _syncCoursesCount();
  }

  Future<void> _fetchInstructors() async {
    try {
      instructors.assignAll(await _instructorRepository.fetchInstructors(instituteId: instituteId));
    } catch (_) {
      instructors.clear();
    }
  }

  InstituteModel _mergeInstitute(InstituteModel? previous, InstituteModel details) {
    if (previous == null) return details;
    return details.copyWith(
      name: details.name.isNotEmpty ? details.name : previous.name,
      city: details.city.isNotEmpty ? details.city : previous.city,
      description: details.description ?? previous.description,
      address: details.address ?? previous.address,
      latitude: details.latitude ?? previous.latitude,
      longitude: details.longitude ?? previous.longitude,
      coursesCount: details.coursesCount > 0 ? details.coursesCount : previous.coursesCount,
      rating: details.rating > 0 ? details.rating : previous.rating,
      logoUrl: details.logoUrl ?? previous.logoUrl,
      coverImageUrl: details.coverImageUrl ?? previous.coverImageUrl,
    );
  }

  void _syncCoursesCount() {
    final current = institute.value;
    if (current == null) return;
    final loaded = courses.length;
    if (loaded <= 0) return;
    if (current.coursesCount < loaded) {
      institute.value = current.copyWith(coursesCount: loaded);
    }
  }
}
