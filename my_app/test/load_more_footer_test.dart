import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/widgets/design_system.dart';

/// ذيل «تحميل المزيد» الموحّد: تحميل تلقائي عند الوصول للنهاية، وحالات التحميل والفشل والنهاية.
void main() {
  Widget host(Widget child) => GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('ar'),
    home: Scaffold(body: child),
  );

  testWidgets('more pages + idle: asks for the next page by itself, once per frame', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(AppLoadMoreFooter(hasMore: true, isLoading: false, failed: false, onLoadMore: () => calls++)),
    );
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(AppInlineLoader), findsOneWidget, reason: 'the loader slot is reserved');
  });

  testWidgets('already loading: no duplicate request', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(AppLoadMoreFooter(hasMore: true, isLoading: true, failed: false, onLoadMore: () => calls++)),
    );
    await tester.pump();
    expect(calls, 0);
    expect(find.byType(AppInlineLoader), findsOneWidget);
  });

  testWidgets('failure: message + retry, no automatic retry loop; the button asks again', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(AppLoadMoreFooter(hasMore: true, isLoading: false, failed: true, onLoadMore: () => calls++)),
    );
    await tester.pump();
    await tester.pump();
    expect(calls, 0);
    expect(find.text('error_load_more_failed'.tr), findsOneWidget);
    await tester.tap(find.text('retry'.tr));
    expect(calls, 1);
  });

  testWidgets('no more pages: nothing is shown and nothing is requested', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(AppLoadMoreFooter(hasMore: false, isLoading: false, failed: false, onLoadMore: () => calls++)),
    );
    await tester.pump();
    expect(calls, 0);
    expect(find.byType(AppInlineLoader), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('autoLoad off: shows the state only (the page triggers by its own scroll listener)', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        AppLoadMoreFooter(hasMore: true, isLoading: false, failed: false, onLoadMore: () => calls++, autoLoad: false),
      ),
    );
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('in a long lazy list: not triggered at the top, then loads page after page at the end', (tester) async {
    final items = List<int>.generate(12, (i) => i).obs;
    final hasMore = true.obs;
    final loading = false.obs;
    var requests = 0;

    Future<void> loadMore() async {
      if (loading.value || !hasMore.value) return;
      requests++;
      loading.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      items.addAll(List<int>.generate(12, (i) => items.length + i));
      if (items.length >= 48) hasMore.value = false;
      loading.value = false;
    }

    await tester.pumpWidget(
      host(
        Obx(() {
          final data = items.toList(growable: false);
          return ListView.builder(
            itemCount: data.length + 1,
            itemBuilder: (_, i) => i == data.length
                ? AppLoadMoreFooter(
                    hasMore: hasMore.value,
                    isLoading: loading.value,
                    failed: false,
                    onLoadMore: loadMore,
                  )
                : SizedBox(height: 120, child: Text('item ${data[i]}')),
          );
        }),
      ),
    );
    await tester.pump();
    expect(requests, 0, reason: 'the end of the list is far below the first screen');

    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
    }
    expect(items.length, 48, reason: 'every page loaded as the user reached the end');
    expect(requests, 3);
    expect(hasMore.value, isFalse);
  });
}
