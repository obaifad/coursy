import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// يكتب ملخص الإطارات لكل مسار سُجّل في integration_test/perf_flows_test.dart إلى
/// build/KEY.timeline_summary.json، وبقية البيانات (زمن الإقلاع…) إلى build/perf_meta.json.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final rest = <String, dynamic>{};
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic> && value.containsKey('traceEvents')) {
          final summary = driver.TimelineSummary.summarize(driver.Timeline.fromJson(value));
          await summary.writeTimelineToFile(entry.key, pretty: true, includeSummary: true);
        } else {
          rest[entry.key] = value;
        }
      }
      await writeResponseData(rest, testOutputFilename: 'perf_meta');
    },
  );
}
