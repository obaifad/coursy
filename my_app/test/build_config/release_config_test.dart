import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// إعدادات نسخة الإصدار: R8 صريح، لا صلاحية لا يستعملها التطبيق، ولا اعتمادية مباشرة لا يستوردها الكود.
void main() {
  test('release build keeps R8 and resource shrinking on explicitly', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final release = RegExp(r'release\s*\{([\s\S]*?)\n        \}').firstMatch(gradle)?.group(1) ?? '';
    expect(release, contains('isMinifyEnabled = true'));
    expect(release, contains('isShrinkResources = true'));
  });

  test('permissions the app does not use are removed from the merged manifest', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    // WorkManager يضيف FOREGROUND_SERVICE؛ فحص التسجيلات مهمة دورية عادية لا تعمل في الواجهة الأمامية.
    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.FOREGROUND_SERVICE" tools:node="remove"/>'),
    );
    expect(manifest, contains('xmlns:tools="http://schemas.android.com/tools"'));
  });

  test('every direct dependency is imported by lib/', () {
    // مثبّتة عمداً لتوافق الإصدارات (انظر التعليق في pubspec.yaml)، لا تُستورد مباشرة.
    const pinnedOnly = {'workmanager_android', 'workmanager_apple', 'workmanager_platform_interface'};
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final deps = <String>[];
    var inDeps = false;
    for (final line in pubspec) {
      if (line.startsWith('dependencies:')) {
        inDeps = true;
        continue;
      }
      if (RegExp(r'^\S').hasMatch(line)) inDeps = false;
      final m = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
      if (inDeps && m != null) deps.add(m.group(1)!);
    }
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    final unused = deps
        .where((d) => d != 'flutter' && !pinnedOnly.contains(d))
        .where((d) => !sources.contains('package:$d/'))
        .toList();
    expect(unused, isEmpty, reason: 'unused packages add size and plugin code to the release');
  });
}
