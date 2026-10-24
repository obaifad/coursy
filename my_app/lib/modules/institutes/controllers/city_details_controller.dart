import 'package:get/get.dart';

import '../../../core/cache/memory_cache.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/network/api_exception.dart';

class CityDetailsController extends GetxController with LatestLoadGuard, SettledLoad {
  final CityRepository _cityRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final loadMoreFailed = false.obs;
  final city = Rxn<CityModel>();
  final institutes = <InstituteModel>[].obs;
  final title = ''.obs;
  final errorMessage = RxnString();

  late final int cityId;
  int _page = 1;
  static const _perPage = 12;

  /// تحديث (الصفحة الأولى) جارٍ: «المزيد» لا يبدأ أثناءه — سيبني على رقم صفحة يتغيّر بعد قليل.
  int _refreshing = 0;

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
      PagedSnapshot<InstituteModel>(items: institutes, hasMore: hasMore.value, page: _page),
    );
  }

  /// التحديث يُبطل «المزيد» الجاري وأي تحديث أقدم: كان رد «المزيد» يصل بعد التحديث فيُلصق صفحة لاحقة
  /// بالصفحة الأولى الجديدة (صفحة ناقصة أو مكرّرة).
  Future<void> load() async {
    final session = beginLoad();
    _refreshing++;
    if (!_hasCityName && institutes.isEmpty) isLoading.value = true;
    errorMessage.value = null;
    try {
      await Future.wait<void>([_fetchCityIfNeeded(), _fetchFirstInstitutesPage(session)]);
      if (shouldApply(session)) _remember();
    } catch (e) {
      if (shouldApply(session) && institutes.isEmpty) errorMessage.value = userErrorMessage(e);
    } finally {
      _refreshing--;
      finishLoad(session, () => isLoading.value = false);
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

  Future<void> _fetchFirstInstitutesPage(LoadSession session) async {
    final result = await _cityRepository.fetchInstitutesByCity(cityId, page: 1, perPage: _perPage);
    applyIfCurrent(session, () {
      institutes.assignAll(result.items);
      // بعد النجاح فقط: تصفيره قبل الطلب كان يجعل «المزيد» بعد تحديث فاشل يكرّر الصفحة الثانية.
      _page = 1;
      hasMore.value = result.hasMore;
    });
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value || _refreshing > 0) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    // تحديث يبدأ بعد هذا يُبطله: الصفحة لا تُلصق بالقائمة الجديدة.
    final session = currentLoad();
    try {
      final next = _page + 1;
      final result = await _cityRepository.fetchInstitutesByCity(cityId, page: next, perPage: _perPage);
      applyIfCurrent(session, () {
        institutes.addAll(result.items);
        _page = next;
        hasMore.value = result.hasMore;
        _remember();
      });
    } catch (_) {
      if (shouldApply(session)) loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
