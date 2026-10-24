import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/network/api_exception.dart';

class PrivateInstructorsController extends GetxController with LatestLoadGuard, InitialLoadState, SettledLoad {
  PrivateInstructorsController(this._repository);

  final InstructorRepository _repository;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isLoadingFilters = false.obs;
  final hasMore = true.obs;
  final loadMoreFailed = false.obs;
  final errorMessage = RxnString();
  final instructors = <InstructorModel>[].obs;

  /// العدد الكلي من الخادم (`total`) للتخصص المختار، لا عدد ما حُمّل من صفحات (15 في الصفحة).
  final totalCount = 0.obs;

  /// ما تعرضه الشارة: الكلي، ولا يقل عمّا ظهر فعلاً (إن لم يرسل الخادم العدد).
  int get displayCount => totalCount.value > instructors.length ? totalCount.value : instructors.length;
  final subjects = <InstructorSubjectModel>[].obs;
  final selectedSubjectKey = RxnString();

  int _page = 1;
  static const _perPage = 15;

  /// رقم آخر طلب «مزيد» — يُطفئ المؤشر صاحبه فقط.
  int _loadMoreCall = 0;

  int? get _selectedSpecializationId => InstructorRepository.specializationIdFromFilterKey(selectedSubjectKey.value);

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      final key = arg['subjectKey']?.toString() ?? arg['key']?.toString();
      if (key != null && key.isNotEmpty) {
        selectedSubjectKey.value = key;
      }
    } else if (arg is String && arg.isNotEmpty) {
      selectedSubjectKey.value = arg;
    } else if (arg is InstructorSubjectModel) {
      selectedSubjectKey.value = arg.key;
    }
    final cachedSubjects = MemoryCache.get<List<InstructorSubjectModel>>(_subjectsKey);
    if (cachedSubjects != null) subjects.assignAll(cachedSubjects.value);
    if (cachedSubjects == null || !cachedSubjects.isFresh()) {
      // هيكل المرشّحات من أول إطار؛ الطلب نفسه بعد حركة الفتح.
      if (subjects.isEmpty) isLoadingFilters.value = true;
      afterRouteSettles(_loadSubjectFilters);
    }
    final cached = MemoryCache.get<PagedSnapshot<InstructorModel>>(_listKey);
    if (cached != null) {
      _restore(cached.value);
      if (cached.isFresh()) return;
    }
    afterRouteSettles(loadInstructors);
  }

  static const _subjectsKeyScope = 'private-instructor-subjects';
  String get _subjectsKey => MemoryCache.key(_subjectsKeyScope);
  String get _listKey => MemoryCache.key('private-instructors', [selectedSubjectKey.value]);

  void _restore(PagedSnapshot<InstructorModel> snapshot) {
    instructors.assignAll(snapshot.items);
    totalCount.value = snapshot.total;
    hasMore.value = snapshot.hasMore;
    _page = snapshot.page;
    errorMessage.value = null;
    isLoading.value = false;
    markLoaded();
  }

  /// [subject]: التخصص الذي جُلبت له البيانات — لا يُكتب تحت مفتاح تخصص صار غير مختار.
  void _remember(String? subject) {
    if (selectedSubjectKey.value != subject) return;
    MemoryCache.put<PagedSnapshot<InstructorModel>>(
      _listKey,
      PagedSnapshot<InstructorModel>(items: instructors, hasMore: hasMore.value, page: _page, total: totalCount.value),
    );
  }

  Future<void> _loadSubjectFilters() async {
    // مفتاح مستقل: تحميل قائمة المدرّسين لا يُلغي تحميل المرشّحات.
    final session = beginLoad('filters');
    isLoadingFilters.value = true;
    try {
      final fresh = await _repository.fetchInstructorSubjectFilters();
      applyIfCurrent(session, () {
        subjects.assignAll(fresh);
        MemoryCache.put<List<InstructorSubjectModel>>(_subjectsKey, List.of(fresh));
      });
    } on ApiCancelledException {
      return;
    } catch (_) {
      // تحديث فاشل يُبقي المرشّحات المعروضة؛ بلا مرشّحات يبقى الشريط فارغاً كما كان.
    } finally {
      applyIfCurrent(session, () => isLoadingFilters.value = false);
    }
  }

  /// تبديل التخصص:
  ///  - يُبطل أولاً أي رد قادم لتخصص سابق (الصفحة الأولى أو «المزيد»): كان رد متأخر يستبدل قائمة التخصص
  ///    الجديد، وصفحة «المزيد» القديمة تُلصق بها.
  ///  - زرناه قبل قليل: قائمته فوراً، وتُحدَّث بصمت إن كانت قديمة.
  ///  - جديد: تُفرَّغ القائمة فيظهر الهيكل (كانت قائمة التخصص السابق تبقى حتى يصل الرد).
  void selectSubject(String? key) {
    if (selectedSubjectKey.value == key) return;
    selectedSubjectKey.value = key;
    beginLoad();
    isLoadingMore.value = false;
    loadMoreFailed.value = false;
    errorMessage.value = null;
    final cached = MemoryCache.get<PagedSnapshot<InstructorModel>>(_listKey);
    if (cached != null) {
      _restore(cached.value);
      if (!cached.isFresh()) loadInstructors();
      return;
    }
    instructors.clear();
    totalCount.value = 0;
    hasMore.value = true;
    resetInitialLoad();
    isLoading.value = true;
    loadInstructors();
  }

  Future<void> loadInstructors() async {
    final session = beginLoad();
    final subject = selectedSubjectKey.value;
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchInstructorsPage(
        page: 1,
        perPage: _perPage,
        isPrivate: true,
        subjectKey: _selectedSpecializationId == null ? selectedSubjectKey.value : null,
        specializationId: _selectedSpecializationId,
      );
      applyIfCurrent(session, () {
        instructors.assignAll(result.items);
        totalCount.value = result.total;
        _page = 1;
        hasMore.value = result.hasMore;
        markLoaded();
        _remember(subject);
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      // تحديث فاشل يُبقي القائمة المعروضة (كانت تُمسح وتحلّ محلها رسالة الخطأ)؛ بلا قائمة: الخطأ مع
      // «إعادة المحاولة».
      if (shouldApply(session) && instructors.isEmpty) {
        errorMessage.value = e is ApiException ? e.message : 'private_instructors_load_failed'.tr;
        hasMore.value = false;
      }
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    final call = ++_loadMoreCall;
    // إن تغيّر التخصص أثناء التحميل تُهمل الصفحة القديمة بدل خلطها بالقائمة الجديدة.
    final session = currentLoad();
    final subject = selectedSubjectKey.value;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchInstructorsPage(
        page: nextPage,
        perPage: _perPage,
        isPrivate: true,
        subjectKey: _selectedSpecializationId == null ? subject : null,
        specializationId: _selectedSpecializationId,
      );
      applyIfCurrent(session, () {
        instructors.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
        _remember(subject);
      });
    } on ApiCancelledException {
      return;
    } catch (_) {
      if (shouldApply(session)) loadMoreFailed.value = true;
    } finally {
      // آخر «مزيد» فقط يُنهي المؤشر: القديم (لتخصص سابق) لا يُطفئه بينما «مزيد» التخصص الجديد جارٍ، فيُطلب
      // الصفحة نفسها مرتين. وتحديث بالسحب أثناءه لا يُبقيه عالقاً.
      if (call == _loadMoreCall) isLoadingMore.value = false;
    }
  }

  Future<void> reloadLocalizedData() async {
    await _loadSubjectFilters();
    await loadInstructors();
  }
}
