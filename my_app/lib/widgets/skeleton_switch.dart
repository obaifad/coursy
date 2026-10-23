import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// يعرض [skeleton] أثناء [loading]، ثم المحتوى بتلاشٍ قصير بدل القطع المفاجئ بينهما.
///
/// - يتلاشى المحتوى فقط إذا سبقه هيكل في هذه الصفحة (التحميل الأول، أو تصنيف جديد). المحتوى الذي كان جاهزاً من
///   البداية (من الكاش) أو الذي يتغيّر وهو معروض (تحديث، ترتيب) لا يتلاشى ولا يومض.
/// - [contentBuilder] لا يُستدعى أثناء التحميل، فلا يُبنى محتوى ثقيل ثم يُهمَل.
/// - [sliver] true داخل CustomScrollView: الهيكل والمحتوى slivers.
/// - تقليل الحركة في النظام يُلغي التلاشي.
class AppSkeletonSwitch extends StatefulWidget {
  const AppSkeletonSwitch({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.contentBuilder,
    this.sliver = false,
  });

  final bool loading;
  final Widget skeleton;
  final WidgetBuilder contentBuilder;
  final bool sliver;

  @override
  State<AppSkeletonSwitch> createState() => _AppSkeletonSwitchState();
}

class _AppSkeletonSwitchState extends State<AppSkeletonSwitch> with SingleTickerProviderStateMixin {
  // في initState لا عند أول استعمال: صفحة بقيت بهيكلها حتى أُغلقت كانت تنشئه لأول مرة داخل dispose()
  // فيبحث الـ Ticker عن TickerMode في شجرة معطّلة (assertion).
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.fast, value: 1);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant AppSkeletonSwitch old) {
    super.didUpdateWidget(old);
    if (old.loading && !widget.loading && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return widget.skeleton;
    final content = widget.contentBuilder(context);
    return widget.sliver
        ? SliverFadeTransition(opacity: _opacity, sliver: content)
        : FadeTransition(opacity: _opacity, child: content);
  }
}
