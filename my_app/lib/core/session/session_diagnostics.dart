import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/app_debug_log.dart';

/// نتيجة قراءة الجلسة من التخزين الآمن عند الإقلاع.
enum SessionBootOutcome {
  /// توكن موجود: مسجّل.
  signedIn,

  /// لا توكن ولم يكن هناك دخول سابق (أو خرج المستخدم): ضيف.
  guest,

  /// كان مسجّلاً (علامة في GetStorage) ولم يُوجد التوكن: التخزين الآمن فقد الجلسة (خطأ فك تشفير مع
  /// `resetOnError`، أو مسح من النظام) — يظهر للمستخدم كأنه خرج وحده.
  lost,

  /// قراءة التخزين الآمن رمت خطأ: يبدأ التطبيق ضيفاً طوال هذه الجلسة.
  readFailed,
}

/// تشخيص الجلسة عند الإقلاع: سطر في سجل التطوير دائماً، وفي نسخ الإصدار تقرير غير قاتل إلى Crashlytics
/// للحالتين الشاذتين فقط ([SessionBootOutcome.lost] و[SessionBootOutcome.readFailed]). لا يُرسل التوكن ولا
/// أي بيانات حساب — النتيجة وعدد المفاتيح والمدة فقط.
abstract final class SessionDiagnostics {
  SessionDiagnostics._();

  /// آخر نتيجة إقلاع (للاختبارات وللسجل).
  static SessionBootOutcome? lastBoot;

  /// بديل Crashlytics في الاختبارات.
  @visibleForTesting
  static void Function(SessionBootOutcome outcome, Object? error, StackTrace? stack)? reporter;

  static void record(
    SessionBootOutcome outcome, {
    required Duration took,
    int keys = 0,
    Object? error,
    StackTrace? stack,
  }) {
    lastBoot = outcome;
    AppDebugLog.session(
      'boot: ${outcome.name} keys=$keys in ${took.inMilliseconds}ms${error == null ? '' : ' error=$error'}',
    );
    if (outcome == SessionBootOutcome.signedIn || outcome == SessionBootOutcome.guest) return;
    final report = reporter;
    if (report != null) {
      report(outcome, error, stack);
      return;
    }
    if (kDebugMode) return;
    try {
      FirebaseCrashlytics.instance.recordError(
        error ?? StateError('session ${outcome.name}'),
        stack ?? StackTrace.current,
        fatal: false,
        reason: 'session boot: ${outcome.name} (keys=$keys, ${took.inMilliseconds}ms)',
      );
    } catch (_) {
      // Firebase لم يُهيّأ: السجل يكفي.
    }
  }
}
