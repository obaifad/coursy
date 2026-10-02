import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/locale_request_guard.dart';

class _Probe extends GetxController with InitialLoadState {}

void main() {
  test('skeleton only before first successful load, again after reset', () {
    final c = _Probe();
    expect(c.isInitialLoad, isTrue);
    c.markLoaded();
    expect(c.isInitialLoad, isFalse);
    c.resetInitialLoad();
    expect(c.isInitialLoad, isTrue);
  });
}
