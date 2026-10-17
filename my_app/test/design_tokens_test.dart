import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/theme/app_fonts.dart';

/// يمنع عودة الأرقام الحرّة: أحجام الخط من سلّم [AppTextSize] فقط وأنصاف الأقطار من [AppRadius] فقط.
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('firebase_options.dart'))
      .toList();

  List<String> offenders(RegExp pattern, bool Function(double value) allowed) {
    final found = <String>[];
    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // AppTextSize.snap(...) يعيد درجة من السلّم دائماً — ما بداخله حساب لا حجم نهائي.
        final line = lines[i].replaceAll(RegExp(r'AppTextSize\.snap\([^;]*\)'), 'AppTextSize.snap()');
        for (final match in pattern.allMatches(line)) {
          for (var g = 1; g <= match.groupCount; g++) {
            final raw = match.group(g);
            if (raw == null) continue;
            final value = double.parse(raw);
            if (!allowed(value)) found.add('${file.path}:${i + 1}  $raw  →  ${lines[i].trim()}');
          }
        }
      }
    }
    return found;
  }

  test('the type ramp has seven whole-pixel sizes', () {
    expect(AppTextSize.ramp, [12.0, 13.0, 14.0, 15.0, 17.0, 20.0, 28.0]);
    expect(AppTextSize.ramp.every((s) => s == s.roundToDouble()), isTrue);
    expect(AppTextSize.snap(16), 15);
    expect(AppTextSize.snap(22.5), 20);
    expect(AppTextSize.snap(11), 12);
  });

  test('the radius scale has five steps', () {
    expect(AppRadius.scale, [8.0, 12.0, 16.0, 24.0, 999.0]);
  });

  test('font sizes in lib/ come from the ramp', () {
    // fontSize: 13   /   fontSize: compact ? 13 : 15
    final pattern = RegExp(r'fontSize:\s*(?:[\w.()<>\s]+\?\s*)?(\d+(?:\.\d+)?)(?:\s*:\s*(\d+(?:\.\d+)?))?\s*[,)]');
    final found = offenders(pattern, AppTextSize.ramp.contains);
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('corner radii in lib/ come from the scale', () {
    final pattern = RegExp(r'(?:BorderRadius|Radius)\.circular\(\s*(\d+(?:\.\d+)?)\s*\)');
    final found = offenders(pattern, (v) => v == 0 || AppRadius.scale.contains(v));
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('no fractional font sizes anywhere in lib/', () {
    final pattern = RegExp(r'fontSize:\s*[^,\n]*?(\d+\.[1-9]\d*)');
    final found = offenders(pattern, (_) => false);
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
