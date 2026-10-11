import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// آخر عمليات البحث على هذا الجهاز — تُمسح عند تسجيل الخروج حتى لا يراها حساب آخر.
class RecentSearchStorage extends GetxService {
  static const _key = 'recent_searches';
  static const _maxItems = 8;

  late final GetStorage _box;
  final queries = <String>[].obs;

  Future<void> init() async {
    _box = GetStorage();
    final raw = _box.read<List<dynamic>>(_key) ?? [];
    queries.assignAll(raw.map((e) => e.toString()).where((s) => s.isNotEmpty));
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    queries.remove(q);
    queries.insert(0, q);
    if (queries.length > _maxItems) {
      queries.removeRange(_maxItems, queries.length);
    }
    await _box.write(_key, queries.toList());
  }

  Future<void> clear() async {
    queries.clear();
    await _box.remove(_key);
  }
}
