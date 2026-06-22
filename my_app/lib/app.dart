import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/locale/app_translations.dart';
import 'core/locale/locale_controller.dart';
import 'core/navigation/app_page_transition.dart';
import 'core/navigation/home_scroll_reset.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class SyrianEducationApp extends StatelessWidget {
  const SyrianEducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<LocaleController>(
      builder: (locale) => GetMaterialApp(
        title: 'app_title'.tr,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        translations: AppTranslations(),
        locale: locale.locale,
        fallbackLocale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        routingCallback: (routing) {
          if (routing?.isBack == true && Get.currentRoute == AppRoutes.root) {
            HomeScrollReset.notifyIfHomeVisible();
          }
        },
        defaultTransition: Transition.fadeIn,
        customTransition: AppFadeScaleTransition(),
        transitionDuration: const Duration(milliseconds: 280),
        builder: (context, child) {
          return Directionality(
            textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
