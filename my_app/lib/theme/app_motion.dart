/// أزمنة الحركة الموحّدة — كل انتقال في التطبيق يستخدم أحد هذين الزمنين.
abstract final class AppMotion {
  /// تبديل حالة صغيرة (شريحة، زر، شارة).
  static const Duration fast = Duration(milliseconds: 200);

  /// تغيير تخطيط أو انتقال صفحة/خطوة.
  static const Duration normal = Duration(milliseconds: 300);
}
