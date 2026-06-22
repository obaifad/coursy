import 'package:get/get.dart';

import 'locale_controller.dart';

/// اقرأ هذا داخل [Obx] لإعادة بناء الواجهة عند تغيير اللغة.
String get localeRebuildToken => Get.find<LocaleController>().code.value;
