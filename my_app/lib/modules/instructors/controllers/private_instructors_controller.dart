import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class PrivateInstructorsController extends GetxController {
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
    isLoadingFilters.value = true;
    try {
      subjects.assignAll(await _repository.fetchInstructorSubjectFilters());
    } catch (_) {
      subjects.clear();
    } finally {
      isLoadingFilters.value = false;
    }
  }

  void selectSubject(String? key) {
    if (selectedSubjectKey.value == key) return;
    selectedSubjectKey.value = key;
    loadInstructors();
  }

  Future<void> loadInstructors() async {
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
      instructors.assignAll(result.items);
      hasMore.value = result.hasMore;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      instructors.clear();
      hasMore.value = false;
    } catch (_) {
      errorMessage.value = 'private_instructors_load_failed'.tr;
      instructors.clear();
      hasMore.value = false;
    } finally {
      isLoading.value = false;
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
