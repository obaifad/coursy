import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// مفضلة محلية (احتياط عند غياب مسار API على الخادم).
class FavoritesStorage extends GetxService {
  static const _key = 'favorite_course_ids';

  late final GetStorage _box;
  final favoriteIds = <int>[].obs;

  Future<void> init() async {
    _box = GetStorage();
    final raw = _box.read<List<dynamic>>(_key) ?? [];
    favoriteIds.assignAll(raw.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0));
  }

  bool isFavorite(int courseId) => favoriteIds.contains(courseId);

  Future<void> add(int courseId) async {
    if (!favoriteIds.contains(courseId)) {
      favoriteIds.add(courseId);
      await _persist();
    }
  }

  Future<void> remove(int courseId) async {
    favoriteIds.remove(courseId);
    await _persist();
  }

  Future<void> toggle(int courseId) async {
    if (isFavorite(courseId)) {
      await remove(courseId);
    } else {
      await add(courseId);
    }
  }

  Future<void> replaceCourseIds(Iterable<int> ids) async {
    favoriteIds.assignAll(ids.where((id) => id > 0).toSet());
    await _persist();
  }

  Future<void> _persist() async {
    await _box.write(_key, favoriteIds.toList());
  }
}
