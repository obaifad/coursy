import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class PrivateInstructorsController extends GetxController with LatestLoadGuard {
  PrivateInstructorsController(this._repository);

  final InstructorRepository _repository;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isLoadingFilters = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final instructors = <InstructorModel>[].obs;
  final subjects = <InstructorSubjectModel>[].obs;
  final selectedSubjectKey = RxnString();

  int _page = 1;
  static const _perPage = 15;

  int? get _selectedSpecializationId =>
      InstructorRepository.specializationIdFromFilterKey(selectedSubjectKey.value);

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
    _loadSubjectFilters();
    loadInstructors();
  }

  Future<void> _loadSubjectFilters() async {
    final session = beginLoad();
    isLoadingFilters.value = true;
    try {
      final fresh = await _repository.fetchInstructorSubjectFilters();
      applyIfCurrent(session, () => subjects.assignAll(fresh));
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
    loadInstructors();
  }

  Future<void> loadInstructors() async {
    final session = beginLoad();
    isLoading.value = true;
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
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> reloadLocalizedData() async {
    await _loadSubjectFilters();
    await loadInstructors();
  }
}
