import 'package:get/get.dart';

import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class InstructorSubjectInstructorsController extends GetxController {
  final InstructorRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final instructors = <InstructorModel>[].obs;
  final title = ''.obs;
  final instructorsCount = 0.obs;

  late final String subjectKey;
  final _allInstructors = <InstructorModel>[];
  int _visibleCount = 0;
  static const _pageSize = 15;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      subjectKey = arg['key']?.toString() ?? '';
      title.value = arg['name']?.toString() ?? 'instructor_subject_default'.tr;
      instructorsCount.value = (arg['instructorsCount'] as int?) ?? 0;
    } else if (arg is InstructorSubjectModel) {
      subjectKey = arg.key;
      title.value = arg.name;
      instructorsCount.value = arg.instructorsCount;
    } else {
      subjectKey = '';
      title.value = 'instructor_subject_default'.tr;
    }
    loadInstructors();
  }

  Future<void> loadInstructors() async {
    isLoading.value = true;
    errorMessage.value = null;
    _visibleCount = 0;
    try {
      _allInstructors
        ..clear()
        ..addAll(await _repository.fetchInstructorsBySubject(subjectKey: subjectKey));
      instructors.assignAll(_allInstructors.take(_pageSize));
      _visibleCount = instructors.length;
      instructorsCount.value = _allInstructors.length;
      hasMore.value = _visibleCount < _allInstructors.length;
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
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextEnd = (_visibleCount + _pageSize).clamp(0, _allInstructors.length);
      instructors.addAll(_allInstructors.sublist(_visibleCount, nextEnd));
      _visibleCount = nextEnd;
      hasMore.value = _visibleCount < _allInstructors.length;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
