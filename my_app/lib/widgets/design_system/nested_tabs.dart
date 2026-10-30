part of '../design_system.dart';

/// قائمة تبويب داخل [NestedScrollView] رأسه ملفوف بـ [SliverOverlapAbsorber]: تبدأ تحت الجزء المثبّت من
/// الرأس (شريط التبويبات) لا خلفه. بدونها كان أول 117–132px من التبويب يختفي تحته حين يُطوى الرأس — تبويب
/// فيه بطاقة واحدة يبدو فارغاً، ولا يمكن إظهار أعلاه إلا بفتح الرأس من جديد.
class AppNestedTabScrollView extends StatelessWidget {
  const AppNestedTabScrollView({super.key, required this.slivers, this.physics});

  final List<Widget> slivers;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics,
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        ...slivers,
      ],
    );
  }
}

/// يكمل طيّ الرأس أو فتحه حين يتوقف التمرير وهو في منتصفه (كان يبقى نصف مطويّ والعنوان مقطوعاً تحت
/// شريط التبويبات): إلى الأقرب من الوضعين.
///
/// مسافة الطيّ تُقرأ من رأس القائمة نفسه (أول sliver مثبّت فيها، داخل [SliverOverlapAbsorber] أو لا)، فيصلح
/// لـ CustomScrollView ولـ NestedScrollView. لا يمسّ إلا التمرير الخارجي (depth 0).
class AppHeaderSnap extends StatelessWidget {
  const AppHeaderSnap({super.key, required this.child});

  final Widget child;

  static const Duration duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(onNotification: _onScrollEnd, child: child);
  }

  bool _onScrollEnd(ScrollEndNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final scrollable = n.context == null ? null : Scrollable.maybeOf(n.context!);
    final extent = scrollable == null ? null : _collapseExtent(scrollable.context.findRenderObject());
    if (extent == null || extent <= 0) return false;
    final pixels = n.metrics.pixels;
    if (pixels <= 0.5 || pixels >= extent - 0.5) return false;
    final target = math.min(pixels < extent / 2 ? 0.0 : extent, n.metrics.maxScrollExtent);
    if ((target - pixels).abs() < 0.5) return false;
    final position = scrollable!.position;
    // بعد انتهاء الإشعار: بدء حركة جديدة داخله يربك منطق نهاية التمرير الحالي.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (position.hasPixels && !position.isScrollingNotifier.value) {
        position.animateTo(target, duration: duration, curve: Curves.easeOutCubic);
      }
    });
    return false;
  }

  /// مسافة طيّ أول رأس مثبّت في القائمة (الأقصى − الأدنى)، أو null إن لم يوجد.
  static double? _collapseExtent(RenderObject? root) {
    RenderViewportBase? viewport;
    void find(RenderObject o) {
      if (viewport != null) return;
      if (o is RenderViewportBase) {
        viewport = o;
        return;
      }
      o.visitChildren(find);
    }

    if (root == null) return null;
    find(root);
    final vp = viewport;
    if (vp == null) return null;
    RenderObject? first;
    vp.visitChildren((c) => first ??= c);
    if (first is RenderSliverOverlapAbsorber) first = (first! as RenderSliverOverlapAbsorber).child;
    if (first is RenderSliverPersistentHeader) {
      final header = first! as RenderSliverPersistentHeader;
      return header.maxExtent - header.minExtent;
    }
    return null;
  }
}

/// آخر قائمة CustomScrollView برأس ينطوي: المحتوى الأطول من الشاشة بقليل لا يكفي لطيّ الرأس كاملاً، فيتوقف
/// نصف مطويّ. هذه المسافة تكمّل مدى التمرير حتى [collapseExtent] بالضبط — فقط حين يتمرّر المحتوى أصلاً
/// (القصير لا يتمرّر ولا يُضاف له شيء) — فيستطيع [AppHeaderSnap] إكمال الطيّ.
class AppCollapseRunway extends StatelessWidget {
  const AppCollapseRunway({super.key, required this.collapseExtent});

  final double collapseExtent;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.precedingScrollExtent;
        final viewport = constraints.viewportMainAxisExtent;
        final missing = content > viewport ? viewport + collapseExtent - content : 0.0;
        return SliverToBoxAdapter(child: SizedBox(height: missing.clamp(0.0, collapseExtent)));
      },
    );
  }
}
