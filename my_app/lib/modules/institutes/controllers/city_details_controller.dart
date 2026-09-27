import 'package:get/get.dart';

import '../../../core/data/repositories/city_repository.dart';
import '../../../core/models/app_models.dart';

class CityDetailsController extends GetxController {
  final CityRepository _cityRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final city = Rxn<CityModel>();
  final institutes = <InstituteModel>[].obs;
  final title = ''.obs;

  late final int cityId;
  int _page = 1;
  static const _perPage = 12;

  /// هل لدينا اسم المدينة الفعلي (وليس العنوان الافتراضي المترجم).
  bool _hasCityName = false;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    String? name;
    if (arg is Map<String, dynamic>) {
      cityId = (arg['id'] as int?) ?? 0;
      name = arg['name']?.toString();
    } else if (arg is CityModel) {
      cityId = arg.id;
      city.value = arg;
      name = arg.name;
    } else {
      cityId = 0;
    }
    _hasCityName = name != null && name.isNotEmpty;
    title.value = _hasCityName ? name! : 'city'.tr;
    load();
  }

  Future<void> load() async {
    if (!_hasCityName) isLoading.value = true;
    _page = 1;
    try {
      await Future.wait<void>([_fetchCityIfNeeded(), _fetchInstitutesPage()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchCityIfNeeded() async {
    if (city.value != null || cityId <= 0) return;
    try {
      city.value = await _cityRepository.fetchCityById(cityId);
      title.value = city.value!.name;
      _hasCityName = true;
    } catch (_) {}
  }

  Future<void> _fetchInstitutesPage() async {
    final result = await _cityRepository.fetchInstitutesByCity(cityId, page: _page, perPage: _perPage);
    institutes.assignAll(result.items);
    hasMore.value = result.hasMore;
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final result = await _cityRepository.fetchInstitutesByCity(cityId, page: next, perPage: _perPage);
      institutes.addAll(result.items);
      _page = next;
      hasMore.value = result.hasMore;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
