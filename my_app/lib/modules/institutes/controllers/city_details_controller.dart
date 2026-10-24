import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/network/api_exception.dart';

class CityDetailsController extends GetxController with SettledLoad {
  final CityRepository _cityRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  /// العدد الكلي لمعاهد المدينة من الخادم (`total`)، لا عدد ما حُمّل من صفحات.
  final totalInstitutes = 0.obs;
  final loadMoreFailed = false.obs;
  final city = Rxn<CityModel>();
  final institutes = <InstituteModel>[].obs;
  final title = ''.obs;
  final errorMessage = RxnString();

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
      cityId = JsonHelpers.parseInt(arg['id']);
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
    final cachedCity = cityId > 0 ? MemoryCache.get<CityModel>(_cityKey) : null;
    if (cachedCity != null && city.value == null) {
      city.value = cachedCity.value;
      title.value = cachedCity.value.name;
      _hasCityName = true;
    }
    final cached = cityId > 0 ? MemoryCache.get<PagedSnapshot<InstituteModel>>(_listKey) : null;
    if (cached != null) {
      institutes.assignAll(cached.value.items);
      totalInstitutes.value = cached.value.total;
      hasMore.value = cached.value.hasMore;
      _page = cached.value.page;
      isLoading.value = false;
      if (cached.isFresh()) return;
    }
    afterRouteSettles(load);
  }

  String get _cityKey => MemoryCache.key('city', [cityId]);
  String get _listKey => MemoryCache.key('city-institutes', [cityId]);

  void _remember() {
    if (city.value != null) MemoryCache.put<CityModel>(_cityKey, city.value!);
    MemoryCache.put<PagedSnapshot<InstituteModel>>(
      _listKey,
      PagedSnapshot<InstituteModel>(
        items: institutes,
        hasMore: hasMore.value,
        page: _page,
        total: totalInstitutes.value,
      ),
    );
  }

  Future<void> load() async {
    if (!_hasCityName && institutes.isEmpty) isLoading.value = true;
    errorMessage.value = null;
    try {
      await Future.wait<void>([_fetchCityIfNeeded(), _fetchFirstInstitutesPage()]);
      _remember();
    } catch (e) {
      if (institutes.isEmpty) errorMessage.value = userErrorMessage(e);
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

  Future<void> _fetchFirstInstitutesPage() async {
    final result = await _cityRepository.fetchInstitutesByCity(cityId, page: 1, perPage: _perPage);
    institutes.assignAll(result.items);
    totalInstitutes.value = result.total;
    // بعد النجاح فقط: تصفيره قبل الطلب كان يجعل «المزيد» بعد تحديث فاشل يكرّر الصفحة الثانية.
    _page = 1;
    hasMore.value = result.hasMore;
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    try {
      final next = _page + 1;
      final result = await _cityRepository.fetchInstitutesByCity(cityId, page: next, perPage: _perPage);
      institutes.addAll(result.items);
      _page = next;
      hasMore.value = result.hasMore;
      _remember();
    } catch (_) {
      loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
