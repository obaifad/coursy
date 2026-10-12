import 'package:flutter/widgets.dart';

/// لمسة على مساحة فارغة تغلق لوحة المفاتيح — في كل الشاشات والنوافذ (حول Navigator التطبيق).
///
/// الأزرار والحقول تكسب اللمسة لأنها أعمق في الشجرة، فلا تتأثر؛ فقط اللمس خارجها يصل إلى هنا.
/// (على الهاتف لا يغلق Flutter لوحة المفاتيح عند اللمس خارج الحقل افتراضياً.)
class DismissKeyboardOnTapOutside extends StatelessWidget {
  const DismissKeyboardOnTapOutside({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
