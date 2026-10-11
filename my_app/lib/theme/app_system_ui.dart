import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// لون أيقونات شريط الحالة (الساعة والبطارية).
///
/// Flutter لا يعيد النمط الافتراضي عند مغادرة شاشة: كل شاشة بلا AppBar تُبقي آخر نمط طُبّق، فكانت
/// الأيقونات تبقى بيضاء على الشاشات الفاتحة بعد زيارة الملف الشخصي. لذلك كل شاشة بلا AppBar تعلن نمطها
/// بـ [AppStatusBar]، وكل AppBar يأخذ [AppSystemUi.darkIcons] من الثيم.
/// (لا نضبط شريط التنقّل السفلي — كما يفعل AppBar.)
abstract final class AppSystemUi {
  /// أيقونات داكنة — فوق الخلفيات الفاتحة (الافتراضي).
  static const darkIcons = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
  );

  /// أيقونات فاتحة — فوق الرؤوس البنفسجية (شاشة البداية، الملف الشخصي، رؤوس القوائم الممتدة للأعلى).
  static const lightIcons = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
  );
}

/// يعلن لون أيقونات شريط الحالة للشاشة التي تحته (لشاشات بلا AppBar).
class AppStatusBar extends StatelessWidget {
  const AppStatusBar({super.key, required this.child, this.lightIcons = false});

  /// true فوق رأس بنفسجي يمتد تحت شريط الحالة.
  final bool lightIcons;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons ? AppSystemUi.lightIcons : AppSystemUi.darkIcons,
      child: child,
    );
  }
}
