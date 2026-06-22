import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'core/bindings/app_bindings.dart';
import 'core/locale/locale_controller.dart';
import 'core/services/favorites_service.dart';
import 'core/storage/favorites_storage.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/recent_search_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  AppBindings().dependencies();
  await Get.find<LocaleController>().init();
  await Get.find<TokenStorage>().init();
  await Get.find<FavoritesStorage>().init();
  await Get.find<RecentSearchStorage>().init();
  if (Get.find<TokenStorage>().isLoggedIn && Get.isRegistered<FavoritesService>()) {
    await Get.find<FavoritesService>().syncFromApi();
  }

  runApp(const SyrianEducationApp());
}
