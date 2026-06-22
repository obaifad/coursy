import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class RecentSearchStorage extends GetxService {
  static const _key = 'recent_searches';

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
    if (queries.length > 8) {
      queries.removeRange(8, queries.length);
    }
    await _box.write(_key, queries.toList());
  }
}
