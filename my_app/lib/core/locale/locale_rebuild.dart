import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'locale_controller.dart';

/// اقرأ هذا داخل [Obx] لإعادة بناء الواجهة عند تغيير اللغة.
String get localeRebuildToken => Get.find<LocaleController>().code.value;

/// يعيد بناء الشجرة عند تغيير اللغة (نصوص .tr + أسماء ثنائية اللغة من الـ API).
class LocaleRebuild extends StatelessWidget {
  const LocaleRebuild({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return builder(context);
    });
  }
}
