import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';

import '../layout/fakes.dart';

/// بعد أول تحميل ناجح لا يعود isLoading إلى true أبداً: التحديثات (سحب، عودة للتبويب، تغيير لغة) صامتة،
/// حتى لو تداخلت مع بعضها.
void main() {
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  testWidgets('overlapping refreshes keep isLoading false once home has data', (tester) async {
    final tokens = await registerFakes(loggedIn: true, locale: 'ar');
    final c = Get.put(HomeController(tokens));
    await tester.pump(const Duration(seconds: 1));
    expect(c.isLoading.value, isFalse);
    expect(c.courses, isNotEmpty);

    final states = <bool>[];
    final worker = ever<bool>(c.isLoading, states.add);
    addTearDown(worker.dispose);

    final gate = FakeApi.gate = Completer<void>();
    unawaited(c.loadHome(forceRefresh: true)); // سحب للتحديث
    unawaited(c.reloadLocalizedData()); // تغيير اللغة أثناءه
    await tester.pump();
    expect(c.isRefreshing.value, isTrue);
    gate.complete();
    await tester.pump(const Duration(seconds: 1));

    expect(states, isNot(contains(true)), reason: 'isLoading went back to true while data was shown');
    expect(c.isLoading.value, isFalse);
    expect(c.isRefreshing.value, isFalse);
    expect(c.courses, isNotEmpty);
  });
}
