import 'package:get/get.dart';

/// جيل عالمي يُزاد عند تغيير اللغة — أي استجابة من جيل أقدم تُتجاهَل.
class LocaleRequestGuard extends GetxService {
  int _generation = 0;

  int get generation => _generation;

  int capture() => _generation;

  int bump() => ++_generation;

  bool isCurrent(int id) => id == _generation;
}

/// جلسة تحميل واحدة: تسلسل محلي + جيل اللغة عند البدء.
class LoadSession {
  const LoadSession({required this.localeGeneration, required this.loadSeq, this.key = defaultKey});

  static const defaultKey = 'default';

  final int localeGeneration;
  final int loadSeq;

  /// نوع التحميل (القائمة الرئيسية، الفلاتر...) — لكل نوع تسلسل مستقل.
  final String key;
}

/// Mixin للـ controllers: فقط آخر طلب (ومن نفس جيل اللغة) يُطبَّق على الـ UI.
///
/// التسلسل منفصل لكل [LoadSession.key]: تحميل الفلاتر (تصنيفات/مدن) لا يُبطل تحميل
/// القائمة والعكس — التسلسل المشترك كان يرمي الفلاتر عند أول فتح للشاشة.
mixin LatestLoadGuard on GetxController {
  final Map<String, int> _loadSeqs = {};

  LocaleRequestGuard get _localeGuard => Get.find<LocaleRequestGuard>();

  LoadSession beginLoad([String key = LoadSession.defaultKey]) {
    final seq = (_loadSeqs[key] ?? 0) + 1;
    _loadSeqs[key] = seq;
    return LoadSession(localeGeneration: _localeGuard.capture(), loadSeq: seq, key: key);
  }

  /// الجلسة الحالية بدون بدء تحميل جديد — لتحميل صفحات إضافية تُلغى إن بدأ تحميل كامل جديد.
  LoadSession currentLoad([String key = LoadSession.defaultKey]) =>
      LoadSession(localeGeneration: _localeGuard.capture(), loadSeq: _loadSeqs[key] ?? 0, key: key);

  bool _isLatest(LoadSession session) => session.loadSeq == _loadSeqs[session.key];

  bool shouldApply(LoadSession session) => _localeGuard.isCurrent(session.localeGeneration) && _isLatest(session);

  void applyIfCurrent(LoadSession session, void Function() apply) {
    if (shouldApply(session)) apply();
  }

  /// يُنهي حالة التحميل فقط إذا كانت هذه أحدث جلسة (حتى بعد إلغاء الطلب).
  void finishLoad(LoadSession session, void Function() resetLoading) {
    if (_isLatest(session)) resetLoading();
  }
}
