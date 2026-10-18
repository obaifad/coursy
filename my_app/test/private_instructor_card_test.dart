import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// بطاقة «مدرّسون خصوصيون» في الرئيسية (بشكل بطاقة الطبيب): تتّسع في شريط الرئيسية بأي حجم خط،
/// وتعرض الصورة الدائرية، الاسم، التخصص، الخبرة، وزراً عريضاً بسعر الساعة.
void main() {
  setUpAll(loadAuditFonts);
  setUp(() => Get.locale = const Locale('ar'));
  tearDown(Get.reset);

  Future<double> pump(WidgetTester tester, InstructorModel instructor, double scale) async {
    late double rail;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(400, 900), textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                rail = PrivateInstructorMiniCard.railHeight(context);
                return Align(
                  alignment: Alignment.topCenter,
                  child: PrivateInstructorMiniCard(instructor: instructor),
                );
              },
            ),
          ),
        ),
      ),
    );
    return rail;
  }

  for (final scale in [1.0, 1.3]) {
    testWidgets('every sample instructor fits the Home rail at text scale $scale', (tester) async {
      for (final instructor in sampleInstructors()) {
        final rail = await pump(tester, instructor, scale);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(PrivateInstructorMiniCard)).height,
          lessThanOrEqualTo(rail),
          reason: instructor.name,
        );
      }
    });
  }

  testWidgets('circular photo on top, name, specialization, experience and an hourly-price button', (tester) async {
    final instructor = InstructorModel.fromJson({
      'id': 7,
      'name_ar': 'طارق ناصر',
      'name_en': 'Tarek Nasser',
      'specialization_ar': 'تطوير تطبيقات الموبايل',
      'specialization_en': 'Mobile App Development',
      'experience_years': 10,
      'hourly_price': 45000,
      'is_private': 1,
    });
    await pump(tester, instructor, 1);

    expect(find.byType(ClipOval), findsOneWidget);
    final photo = tester.getRect(find.byType(ClipOval));
    final name = tester.getRect(find.text(instructor.name));
    expect(photo.bottom, lessThan(name.top));
    expect(find.text(instructor.specializationLabel!), findsOneWidget);
    expect(find.textContaining('hourly_rate_label'.tr), findsOneWidget);
  });

  group('profile photo frame and fallback icons', () {
    InstructorModel person(Map<String, dynamic> extra) =>
        InstructorModel.fromJson({'id': 1, 'name_ar': 'أحمد', 'name_en': 'Ahmad', 'hourly_price': 30000, ...extra});

    test('gender is read from male/female spellings, unknown stays null', () {
      expect(person({'gender': 'male'}).gender, 'male');
      expect(person({'gender': 'Female'}).gender, 'female');
      expect(person({'gender': 'ذكر'}).gender, 'male');
      expect(person({'gender': 'أنثى'}).gender, 'female');
      expect(person({'gender': 'other'}).gender, isNull);
      expect(person({}).gender, isNull);
    });

    testWidgets('the photo sits in a soft theme-coloured circular border', (tester) async {
      await pump(tester, person({'image': 'https://coursy.sy/storage/i.jpg'}), 1);
      final frame = tester.widget<Container>(
        find.ancestor(of: find.byType(ClipOval), matching: find.byType(Container)).first,
      );
      final decoration = frame.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      final border = decoration.border! as Border;
      expect(border.top.color.toARGB32() & 0x00FFFFFF, AppColors.primary.toARGB32() & 0x00FFFFFF);
      expect(border.top.width, inInclusiveRange(2, 3));
      expect(find.byIcon(Icons.person_rounded), findsNothing, reason: 'a real photo is shown as is');
    });

    for (final (gender, icon) in [
      ('male', Icons.man_rounded),
      ('female', Icons.woman_rounded),
      (null, Icons.person_rounded),
    ]) {
      testWidgets('no photo + gender $gender -> $icon in the theme colour', (tester) async {
        await pump(tester, person({'gender': ?gender}), 1);
        final shown = tester.widget<Icon>(find.byIcon(icon));
        expect(shown.color, AppColors.primary);
        for (final other in [Icons.man_rounded, Icons.woman_rounded, Icons.person_rounded].where((i) => i != icon)) {
          expect(find.byIcon(other), findsNothing);
        }
      });
    }
  });
}
