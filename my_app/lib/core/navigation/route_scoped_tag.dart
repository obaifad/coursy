/// وسم (tag) فريد لكل فتح لصفحة تفاصيل، حتى تعمل نسختان من الصفحة نفسها في المكدّس
/// (دورة ← معهد ← دورة أخرى) كلٌّ بمتحكّمها. بدونه يتجاهل GetX الـ lazyPut الثاني لأن
/// المتحكّم مسجّل مسبقاً، فتعرض الصفحة الثانية بيانات الأولى ويحجز زرّها الدورة الخطأ.
///
/// GetPageRoute يشغّل الـ binding ثم يبني الصفحة مباشرةً (مرة واحدة لكل مسار):
/// الـ binding يحجز وسماً جديداً بـ [reserve] والصفحة تأخذه بـ [take].
abstract final class RouteScopedTag {
  static int _counter = 0;
  static String? _pending;
  static String _last = '';

  static String reserve(String prefix) {
    final tag = '$prefix#${++_counter}';
    _pending = tag;
    _last = tag;
    return tag;
  }

  static String take() {
    final tag = _pending ?? _last;
    _pending = null;
    return tag;
  }
}
