import '../../../core/navigation/route_settle.dart';
import '../../../core/cache/memory_cache.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/data/repositories/institute_repository.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class InstitutesController extends GetxController with LatestLoadGuard, InitialLoadState {
  final InstituteRepository _repository = Get.find();
  final CityRepository _cityRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  /// فشل آخر «تحميل المزيد»: الذيل يعرض رسالة وزر إعادة محاولة بدل إعادة المحاولة التلقائية.
  final loadMoreFailed = false.obs;
  final errorMessage = RxnString();
  final institutes = <InstituteModel>[].obs;

  /// العدد الكلي من الخادم (`total`) للمدينة المختارة، لا عدد ما حُمّل من صفحات (كانت الشارة تعرض 12 من 60).
  final totalCount = 0.obs;

  /// ما تعرضه الشارة: الكلي، ولا يقل عمّا ظهر فعلاً (إن لم يرسل الخادم العدد).
  int get displayCount => totalCount.value > institutes.length ? totalCount.value : institutes.length;
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
    final session = beginLoad('cities');
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
    resetInitialLoad();
    loadInstitutes();
  }

  Future<void> loadInstitutes() async {
    final session = beginLoad();
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    loadMoreFailed.value = false;
    try {
      final result = await _repository.fetchInstitutesPage(
        page: 1,
        perPage: _perPage,
        query: {if (selectedCityId.value != null) 'city_id': selectedCityId.value},
      );
      applyIfCurrent(session, () {
        institutes.assignAll(result.items);
        totalCount.value = result.total;
        // العدّاد يعود للصفحة الأولى مع بياناتها فقط: كان يُصفَّر قبل الطلب، فبعد تحديث فاشل يُعيد
        // «المزيد» الصفحة الثانية فوق قائمة تحتويها (عناصر مكرّرة).
        _page = 1;
        hasMore.value = result.hasMore;
        markLoaded();
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = userErrorMessage(e);
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMoreInstitutes() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    // إن تغيّرت المدينة أثناء التحميل تُهمل الصفحة القديمة بدل خلطها بالقائمة الجديدة.
    final session = currentLoad();
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchInstitutesPage(
        page: nextPage,
        perPage: _perPage,
        query: {if (selectedCityId.value != null) 'city_id': selectedCityId.value},
      );
      applyIfCurrent(session, () {
        institutes.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
      });
    } catch (_) {
      // الذيل يعرض الفشل مع «إعادة المحاولة» (كانت القائمة تنتهي بصمت عند انقطاع الشبكة).
      if (shouldApply(session)) loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}

class InstituteDetailsController extends GetxController with SettledLoad {
  /// صفحات تفاصيل المعاهد المفتوحة الآن — لكلٍّ متحكّمها بوسمٍ خاص، فلا يصلح Get.find بدون وسم.
  static final Set<InstituteDetailsController> _open = {};
  static List<InstituteDetailsController> get open => List.of(_open);

  final InstituteRepository _instituteRepository = Get.find();
  final CourseRepository _courseRepository = Get.find();
  final InstructorRepository _instructorRepository = Get.find();

  final isLoading = true.obs;
  final institute = Rxn<InstituteModel>();
  final courses = <CourseModel>[].obs;
  final instructors = <InstructorModel>[].obs;

  /// أخطاء التحميل: كانت تُبتلع فتظهر «لا دورات/لا مدرّسين» بدل «تعذّر التحميل» مع إعادة المحاولة.
  final detailsError = RxnString();
  final coursesError = RxnString();
  final instructorsError = RxnString();

  late final int instituteId;

  @override
  void onInit() {
    super.onInit();
    _open.add(this);
    final arg = Get.arguments;
    if (arg is InstituteModel) {
      instituteId = arg.id;
      institute.value = arg;
    } else if (arg is int) {
      instituteId = arg;
    } else {
      instituteId = 0;
    }
    final cached = _restoreFromCache();
    if (cached != null && cached.isFresh()) return;
    // الطلبات بعد حركة الفتح: ردّ أثناء الحركة كان يعيد بناء الصفحة وهي تتحرك.
    afterRouteSettles(loadDetails);
  }

  String get _cacheKey => MemoryCache.key('institute-details', [instituteId]);

  /// آخر ما عُرض للمعهد (بياناته ودوراته ومدرّسوه): فوراً عند العودة، وتحديث صامت إن كان قديماً.
  CacheEntry<_InstituteSnapshot>? _restoreFromCache() {
    if (instituteId <= 0) return null;
    final cached = MemoryCache.get<_InstituteSnapshot>(_cacheKey);
    if (cached == null) return null;
    final s = cached.value;
    institute.value = s.institute;
    courses.assignAll(s.courses);
    instructors.assignAll(s.instructors);
    isLoading.value = false;
    return cached;
  }

  void _remember() {
    final current = institute.value;
    if (current == null || instituteId <= 0) return;
    // لا نحفظ حالة ناقصة بسبب خطأ: كانت ستعرض «لا دورات» بدل إعادة المحاولة.
    if (coursesError.value != null || instructorsError.value != null) return;
    MemoryCache.put<_InstituteSnapshot>(
      _cacheKey,
      _InstituteSnapshot(institute: current, courses: List.of(courses), instructors: List.of(instructors)),
    );
  }

  @override
  void onClose() {
    _open.remove(this);
    super.onClose();
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
      final ok = await Future.wait<bool>([_fetchInstituteDetails(), _fetchCourses(), _fetchInstructors()]);
      // لا نحفظ حالة جزئية: كانت تُعلَّم «طازجة» فلا يُعاد الطلب عند العودة.
      if (ok.every((v) => v)) _remember();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _fetchInstituteDetails() async {
    if (instituteId <= 0) {
      if (institute.value == null) detailsError.value = 'error_unexpected'.tr;
      return false;
    }
    detailsError.value = null;
    try {
      final details = await _instituteRepository.fetchInstituteById(instituteId);
      institute.value = _mergeInstitute(institute.value, details);
      return true;
    } catch (e) {
      // بيانات الانتقال تكفي للعرض؛ بدونها نعرض الخطأ مع «إعادة المحاولة».
      if (institute.value == null) detailsError.value = userErrorMessage(e);
      return false;
    }
  }

  /// تحديث فاشل لا يمسح ما يُعرض (من الذاكرة أو التحميل السابق): كان يُفرغ القائمة فتظهر «لا دورات».
  /// بلا بيانات: الخطأ مع «إعادة المحاولة».
  Future<bool> _fetchCourses() async {
    coursesError.value = null;
    try {
      // يجرّب `/institutes/{id}/courses` ثم `/courses?institute_id=` بكل الصفحات.
      courses.assignAll(await _courseRepository.fetchInstituteCourses(instituteId));
      _syncCoursesCount();
      return true;
    } catch (e) {
      if (courses.isEmpty) coursesError.value = userErrorMessage(e);
      return false;
    }
  }

  Future<bool> _fetchInstructors() async {
    instructorsError.value = null;
    try {
      instructors.assignAll(await _instructorRepository.fetchInstructors(instituteId: instituteId));
      return true;
    } catch (e) {
      if (instructors.isEmpty) instructorsError.value = userErrorMessage(e);
      return false;
    }
  }

  InstituteModel _mergeInstitute(InstituteModel? previous, InstituteModel details) {
    if (previous == null) return details;
    // النسختان العربية والإنجليزية منفصلتان — تمرير `name` المترجم كان يثبّت لغة واحدة.
    return details.copyWith(
      nameAr: details.nameAr.isNotEmpty ? details.nameAr : previous.nameAr,
      nameEn: details.nameEn.isNotEmpty ? details.nameEn : previous.nameEn,
      cityAr: details.cityAr.isNotEmpty ? details.cityAr : previous.cityAr,
      cityEn: details.cityEn.isNotEmpty ? details.cityEn : previous.cityEn,
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

/// ما يُحفظ لصفحة معهد: بياناته + دوراته + مدرّسوه.
class _InstituteSnapshot {
  _InstituteSnapshot({required this.institute, required this.courses, required this.instructors});

  final InstituteModel institute;
  final List<CourseModel> courses;
  final List<InstructorModel> instructors;
}
