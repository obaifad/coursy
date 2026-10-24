import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/data/repositories/instructor_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/navigation/route_settle.dart';

class InstructorSubjectInstructorsController extends GetxController
    with LatestLoadGuard, InitialLoadState, SettledLoad {
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
      instructorsCount.value = JsonHelpers.parseInt(arg['instructorsCount']);
    } else if (arg is InstructorSubjectModel) {
      subjectKey = arg.key;
      title.value = arg.name;
      instructorsCount.value = arg.instructorsCount;
    } else {
      subjectKey = '';
      title.value = 'instructor_subject_default'.tr;
    }
    final cached = MemoryCache.get<List<InstructorModel>>(_cacheKey);
    if (cached != null) {
      _apply(cached.value);
      isLoading.value = false;
      markLoaded();
      if (cached.isFresh()) return;
    }
    afterRouteSettles(loadInstructors);
  }

  String get _cacheKey => MemoryCache.key('subject-instructors', [subjectKey]);

  void _apply(List<InstructorModel> all) {
    _allInstructors
      ..clear()
      ..addAll(all);
    instructors.assignAll(_allInstructors.take(_pageSize));
    _visibleCount = instructors.length;
    instructorsCount.value = _allInstructors.length;
    hasMore.value = _visibleCount < _allInstructors.length;
  }

  /// «المزيد» هنا محلي (يكشف المزيد من القائمة المحمّلة كلها) فلا يتسابق مع التحديث. ما يُحمى: تحديثان
  /// متداخلان (الجلب بعد حركة الفتح ثم سحب للتحديث) — الأحدث يُطبَّق، والرد الأقدم المتأخر يُهمل.
  Future<void> loadInstructors() async {
    final session = beginLoad();
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    try {
      final all = await _repository.fetchInstructorsBySubject(subjectKey: subjectKey);
      if (!shouldApply(session)) return;
      _apply(all);
      markLoaded();
      MemoryCache.put<List<InstructorModel>>(_cacheKey, List.of(_allInstructors));
    } catch (e) {
      // تحديث فاشل يُبقي القائمة المعروضة؛ بلا قائمة: الخطأ مع «إعادة المحاولة».
      if (shouldApply(session) && instructors.isEmpty) {
        errorMessage.value = e is ApiException ? e.message : 'private_instructors_load_failed'.tr;
        hasMore.value = false;
      }
    } finally {
      finishLoad(session, () => isLoading.value = false);
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
