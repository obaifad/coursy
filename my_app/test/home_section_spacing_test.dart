import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/home/views/home_view.dart';
import 'package:my_app/modules/home/widgets/home_categories_grid.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// الفراغ الظاهر بين أقسام الرئيسية (آخر محتوى القسم ← عنوان القسم التالي) كان بين 41 و63: مساحة ظل
/// البطاقات (28) فوق فراغ القسم، و36 فوق «مدرسون خصوصيون» وحدها، وشريط المدرسين أطول من بطاقاته.
/// الآن موحّد: نفس الفراغ في كل مكان، و~28 حتى نص العنوان بحجم الخط العادي (~32 للعين حتى أعلى الحروف).
const _gap = 28.0;

void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  for (final locale in ['ar', 'en']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('the gap between home sections is the same everywhere ($locale x$scale)', (tester) async {
        Get.locale = Locale(locale);
        final tokens = await registerFakes(loggedIn: true, locale: locale);
        final controller = Get.put(HomeController(tokens));
        tester.view.physicalSize = const Size(360, 5000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          auditApp(child: const HomeView(), locale: locale, scale: scale, boundaryKey: GlobalKey()),
        );
        await tester.pump(const Duration(milliseconds: 600));
        controller.privateInstructors.assignAll(sampleInstructors());
        controller.instructorSubjects.assignAll([
          InstructorSubjectModel(key: 'math', name: 'رياضيات', instructorsCount: 2),
        ]);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        Rect rect(Finder f) => tester.getRect(f);
        double titleTop(String key) => rect(find.text(key.tr)).top;
        double bottomOf(Finder f) => rect(f.first).bottom;

        // تحت التصنيفات أقل بـ 8: نص العدد الصغير يترك فراغاً داخل سطره فيبدو للعين كغيره.
        final gaps = <String, double>{
          'categories → featured': titleTop('section_featured') - bottomOf(find.byType(HomeCategoriesGrid)) + 8,
          'featured → suggested': titleTop('section_suggested') - bottomOf(find.byType(CourseCard)),
          'suggested → tutors': titleTop('section_private_instructors') - rect(find.byType(CourseCard).last).bottom,
          'tutors → institutes': titleTop('section_institutes') - bottomOf(_tutorCard),
        };
        final values = gaps.values.toList()..sort();
        expect(values.last - values.first, lessThan(1), reason: 'not uniform: $gaps');
        // مع تكبير الخط يقترب النص من أعلى عنوانه (زر «عرض الكل» بارتفاع ثابت 44) فيصغر الفراغ قليلاً.
        if (scale == 1.0) {
          for (final MapEntry(:key, :value) in gaps.entries) {
            expect(value, moreOrLessEquals(_gap, epsilon: 1.5), reason: '$key → $gaps');
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}

/// الحاوية البيضاء لبطاقة المدرّس.
final _tutorCard = find.descendant(of: find.byType(PrivateInstructorMiniCard), matching: find.byType(DecoratedBox));
