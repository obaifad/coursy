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
  const LoadSession({required this.localeGeneration, required this.loadSeq});

  final int localeGeneration;
  final int loadSeq;
}

/// Mixin للـ controllers: فقط آخر طلب (ومن نفس جيل اللغة) يُطبَّق على الـ UI.
mixin LatestLoadGuard on GetxController {
  int _loadSeq = 0;

  LocaleRequestGuard get _localeGuard => Get.find<LocaleRequestGuard>();

  LoadSession beginLoad() => LoadSession(
        localeGeneration: _localeGuard.capture(),
        loadSeq: ++_loadSeq,
      );

  bool shouldApply(LoadSession session) =>
      _localeGuard.isCurrent(session.localeGeneration) && session.loadSeq == _loadSeq;

  void applyIfCurrent(LoadSession session, void Function() apply) {
    if (shouldApply(session)) apply();
  }

  /// يُنهي حالة التحميل فقط إذا كانت هذه أحدث جلسة (حتى بعد إلغاء الطلب).
  void finishLoad(LoadSession session, void Function() resetLoading) {
    if (session.loadSeq == _loadSeq) resetLoading();
  }
}
