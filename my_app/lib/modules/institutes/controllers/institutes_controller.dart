import '../../../core/navigation/route_settle.dart';
import '../../../core/cache/memory_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/data/repositories/institute_repository.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/data/repositories/review_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/course_rating_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/auth_guard.dart';
import '../../../routes/app_routes.dart';

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

  /// قائمة مدينة أخرى تبدأ من أولها، لا من موضع القائمة السابقة.
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _loadCities();
    loadInstitutes();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
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

  /// لكل مدينة (و«الكل») قائمتها وترقيمها.
  String _cacheKey(int? cityId) => MemoryCache.key('institutes-tab', [cityId ?? 'all']);

  /// يحفظ ما حُمّل لمدينة (العناصر وحالة الترقيم) كي يعود إليها المستخدم فوراً.
  void _remember(int? cityId) {
    if (selectedCityId.value != cityId) return;
    MemoryCache.put<PagedSnapshot<InstituteModel>>(
      _cacheKey(cityId),
      PagedSnapshot<InstituteModel>(items: institutes, hasMore: hasMore.value, page: _page, total: totalCount.value),
    );
  }

  /// تبديل المدينة:
  ///  - المحددة نفسها: لا شيء.
  ///  - زرناها قبل قليل: فوراً بلا هيكل؛ تُحدَّث بصمت إن قدمت (3 دقائق).
  ///  - جديدة: تُفرَّغ القائمة فوراً فيظهر الهيكل — كانت قائمة المدينة السابقة وشارة عددها تبقيان ظاهرتين
  ///    حتى يصل الرد، بجانب شريحة المدينة الجديدة.
  void selectCity(int? id) {
    if (selectedCityId.value == id) return;
    selectedCityId.value = id;
    _scrollToTop();
    // يُبطل أي رد قادم لمدينة سابقة (الصفحة الأولى أو «المزيد»).
    beginLoad();
    isLoadingMore.value = false;
    loadMoreFailed.value = false;
    errorMessage.value = null;

    final cached = MemoryCache.get<PagedSnapshot<InstituteModel>>(_cacheKey(id));
    if (cached != null) {
      final snapshot = cached.value;
      institutes.assignAll(snapshot.items);
      totalCount.value = snapshot.total;
      hasMore.value = snapshot.hasMore;
      _page = snapshot.page;
      isLoading.value = false;
      markLoaded();
      if (!cached.isFresh()) loadInstitutes();
      return;
    }
    institutes.clear();
    totalCount.value = 0;
    hasMore.value = true;
    resetInitialLoad();
    isLoading.value = true;
    loadInstitutes();
  }

  void _scrollToTop() {
    if (scrollController.hasClients && scrollController.offset > 0) scrollController.jumpTo(0);
  }

  Future<void> loadInstitutes() async {
    final session = beginLoad();
    final cityId = selectedCityId.value;
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    loadMoreFailed.value = false;
    try {
      final result = await _repository.fetchInstitutesPage(
        page: 1,
        perPage: _perPage,
        query: {if (cityId != null) 'city_id': cityId},
      );
      applyIfCurrent(session, () {
        institutes.assignAll(result.items);
        totalCount.value = result.total;
        // العدّاد يعود للصفحة الأولى مع بياناتها فقط: كان يُصفَّر قبل الطلب، فبعد تحديث فاشل يُعيد
        // «المزيد» الصفحة الثانية فوق قائمة تحتويها (عناصر مكرّرة).
        _page = 1;
        hasMore.value = result.hasMore;
        markLoaded();
        _remember(cityId);
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
    final cityId = selectedCityId.value;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchInstitutesPage(
        page: nextPage,
        perPage: _perPage,
        query: {if (cityId != null) 'city_id': cityId},
      );
      applyIfCurrent(session, () {
        institutes.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
        _remember(cityId);
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
  final ReviewRepository _reviewRepository = Get.find();

  final isLoading = true.obs;
  final institute = Rxn<InstituteModel>();

  /// هل وصلت بيانات المعهد؟ لا يتغيّر مع كل تحديث لها، فيتابعه هيكل الصفحة بدل [institute].
  final hasInstitute = false.obs;
  final courses = <CourseModel>[].obs;
  final instructors = <InstructorModel>[].obs;

  /// تقييمات المعهد كما يرسلها الخادم: تقييمات المعهد نفسه وتقييمات دوراته معاً (`type` يميّزها).
  final reviews = <ReviewModel>[].obs;
  final reviewsError = RxnString();

  /// نموذج تقييم المعهد (نجوم فقط)، ووضع «تعديل» حين يكون للطالب تقييم سابق.
  final reviewRating = 5.obs;
  final isEditingReview = false.obs;
  final isSubmittingReview = false.obs;
  final isDeletingReview = false.obs;

  /// أخطاء التحميل: كانت تُبتلع فتظهر «لا دورات/لا مدرّسين» بدل «تعذّر التحميل» مع إعادة المحاولة.
  final detailsError = RxnString();
  final coursesError = RxnString();
  final instructorsError = RxnString();

  late final int instituteId;

  @override
  void onInit() {
    super.onInit();
    _open.add(this);
    ever<InstituteModel?>(institute, (value) => hasInstitute.value = value != null);
    final arg = Get.arguments;
    if (arg is InstituteModel) {
      instituteId = arg.id;
      institute.value = arg;
    } else if (arg is int) {
      instituteId = arg;
    } else {
      instituteId = 0;
    }
    hasInstitute.value = institute.value != null;
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
    reviews.assignAll(s.reviews);
    isLoading.value = false;
    return cached;
  }

  void _remember() {
    final current = institute.value;
    if (current == null || instituteId <= 0) return;
    // لا نحفظ حالة ناقصة بسبب خطأ: كانت ستعرض «لا دورات» بدل إعادة المحاولة.
    if (coursesError.value != null || instructorsError.value != null || reviewsError.value != null) return;
    MemoryCache.put<_InstituteSnapshot>(
      _cacheKey,
      _InstituteSnapshot(
        institute: current,
        courses: List.of(courses),
        instructors: List.of(instructors),
        reviews: List.of(reviews),
      ),
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
      final ok = await Future.wait<bool>([
        _fetchInstituteDetails(),
        _fetchCourses(),
        _fetchInstructors(),
        _fetchReviews(),
      ]);
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

  Future<bool> _fetchReviews() async {
    if (instituteId <= 0) return false;
    reviewsError.value = null;
    try {
      reviews.assignAll(await _reviewRepository.fetchReviews(instituteId: instituteId));
      return true;
    } catch (e) {
      if (reviews.isEmpty) reviewsError.value = userErrorMessage(e);
      return false;
    }
  }

  bool get isLoggedIn => AuthGuard.isLoggedIn;

  /// من بطاقة «سجّل الدخول لتقييم المعهد»: بعد العودة مسجّلاً تُعاد التفاصيل كي يصل `can_review`.
  Future<void> loginToReview() async {
    await Get.toNamed(AppRoutes.login);
    if (!isClosed && isLoggedIn) await loadDetails();
  }

  void startEditingReview() {
    final mine = institute.value?.myReview;
    reviewRating.value = mine == null ? 5 : mine.rating.clamp(1, 5);
    isEditingReview.value = true;
  }

  void cancelEditingReview() {
    isEditingReview.value = false;
    reviewRating.value = 5;
  }

  /// يضيف تقييم الطالب للمعهد أو يعدّله (الخادم يحفظ تقييماً واحداً لكل طالب)، ثم يجلب التفاصيل
  /// والتقييمات من جديد: المتوسط والعدد و`my_review` من الخادم، لا محسوبة هنا.
  Future<void> submitReview() async {
    final current = institute.value;
    if (current == null || instituteId <= 0 || isSubmittingReview.value || isDeletingReview.value) return;
    // القفل قبل أي انتظار: ضغطة ثانية أثناء الإرسال كانت سترسل مرتين.
    isSubmittingReview.value = true;
    try {
      if (!await AuthGuard.requireLogin(message: 'institute_review_login_required'.tr)) return;
      final updating = current.myReview != null;
      if (!updating && !current.canReview) {
        AppToast.show('alert'.tr, 'institute_review_not_eligible'.tr);
        return;
      }
      final saved = await _reviewRepository.submitInstituteReview(instituteId: instituteId, rating: reviewRating.value);
      // يظهر التقييم فوراً حتى لو فشل التحديث بعده.
      institute.value = institute.value?.copyWith(myReview: saved);
      cancelEditingReview();
      await _refreshAfterReviewChange();
      AppToast.show(
        'review_submitted_title'.tr,
        updating ? 'institute_review_updated_msg'.tr : 'review_submitted_msg'.tr,
        kind: ToastKind.success,
      );
    } on ApiException catch (e) {
      AppToast.show('error'.tr, e.message);
    } catch (_) {
      AppToast.show('error'.tr, 'review_submit_failed'.tr);
    } finally {
      isSubmittingReview.value = false;
    }
  }

  Future<void> deleteMyReview() async {
    if (instituteId <= 0 || isDeletingReview.value || isSubmittingReview.value) return;
    if (institute.value?.myReview == null) return;
    isDeletingReview.value = true;
    try {
      await _reviewRepository.deleteMyInstituteReview(instituteId);
      institute.value = institute.value?.copyWith(clearMyReview: true);
      cancelEditingReview();
      await _refreshAfterReviewChange();
      AppToast.show('institute_review_deleted_title'.tr, 'institute_review_deleted_msg'.tr, kind: ToastKind.success);
    } on ApiException catch (e) {
      AppToast.show('error'.tr, e.message);
    } catch (_) {
      AppToast.show('error'.tr, 'institute_review_delete_failed'.tr);
    } finally {
      isDeletingReview.value = false;
    }
  }

  /// بعد إضافة أو حذف: المتوسط والعدد تغيّرا على الخادم. كاش تقييمات المعاهد (يكمّل تقييم الدورات
  /// والقوائم) قديم الآن.
  Future<void> _refreshAfterReviewChange() async {
    if (Get.isRegistered<CourseRatingService>()) Get.find<CourseRatingService>().invalidateCache();
    final ok = await Future.wait<bool>([_fetchInstituteDetails(), _fetchReviews()]);
    if (ok.every((v) => v)) _remember();
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
      // الخادم أرسل عدد التقييمات: تقييمه هو الصحيح حتى لو صفراً (حُذف آخر تقييم). بدونه كان يبقى
      // التقييم السابق من القائمة.
      rating: details.rating > 0 || details.reviewsCount != null ? details.rating : previous.rating,
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

/// ما يُحفظ لصفحة معهد: بياناته + دوراته + مدرّسوه + تقييماته.
class _InstituteSnapshot {
  _InstituteSnapshot({
    required this.institute,
    required this.courses,
    required this.instructors,
    required this.reviews,
  });

  final InstituteModel institute;
  final List<CourseModel> courses;
  final List<InstructorModel> instructors;
  final List<ReviewModel> reviews;
}
