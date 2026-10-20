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
  final subjects = <InstructorSubjectModel>[].obs;
  final selectedSubjectKey = RxnString();

  int _page = 1;
  static const _perPage = 15;

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
    hasMore.value = snapshot.hasMore;
    _page = snapshot.page;
    errorMessage.value = null;
    isLoading.value = false;
    markLoaded();
  }

  void _remember() => MemoryCache.put<PagedSnapshot<InstructorModel>>(
    _listKey,
    PagedSnapshot<InstructorModel>(items: instructors, hasMore: hasMore.value, page: _page),
  );

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
      if (shouldApply(session)) subjects.clear();
    } finally {
      applyIfCurrent(session, () => isLoadingFilters.value = false);
    }
  }

  void selectSubject(String? key) {
    if (selectedSubjectKey.value == key) return;
    selectedSubjectKey.value = key;
    final cached = MemoryCache.get<PagedSnapshot<InstructorModel>>(_listKey);
    if (cached != null) {
      // فلتر زرناه قبل قليل: قائمته فوراً، وتُحدَّث بصمت إن كانت قديمة.
      _restore(cached.value);
      if (!cached.isFresh()) loadInstructors();
      return;
    }
    resetInitialLoad();
    loadInstructors();
  }

  Future<void> loadInstructors() async {
    final session = beginLoad();
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchInstructorsPage(
        page: _page,
        perPage: _perPage,
        isPrivate: true,
        subjectKey: _selectedSpecializationId == null ? selectedSubjectKey.value : null,
        specializationId: _selectedSpecializationId,
      );
      applyIfCurrent(session, () {
        instructors.assignAll(result.items);
        hasMore.value = result.hasMore;
        markLoaded();
        _remember();
      });
    } on ApiCancelledException {
      return;
    } on ApiException catch (e) {
      if (shouldApply(session)) {
        errorMessage.value = e.message;
        instructors.clear();
        hasMore.value = false;
      }
    } catch (_) {
      if (shouldApply(session)) {
        errorMessage.value = 'private_instructors_load_failed'.tr;
        instructors.clear();
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
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchInstructorsPage(
        page: nextPage,
        perPage: _perPage,
        isPrivate: true,
        subjectKey: _selectedSpecializationId == null ? selectedSubjectKey.value : null,
        specializationId: _selectedSpecializationId,
      );
      instructors.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
      _remember();
    } catch (_) {
      loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> reloadLocalizedData() async {
    await _loadSubjectFilters();
    await loadInstructors();
  }
}
