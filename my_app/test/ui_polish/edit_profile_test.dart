import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/auth/widgets/register_form_widgets.dart';
import 'package:my_app/modules/profile/controllers/profile_controller.dart';
import 'package:my_app/modules/profile/views/profile_views.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';

Future<ProfileController> _pumpEditProfile(WidgetTester tester, {bool emailVerified = true}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Get.locale = const Locale('ar');
  final tokens = await registerFakes(loggedIn: true, locale: 'ar');
  await tokens.saveEmailVerified(emailVerified);
  final controller = Get.put(ProfileController());
  await tester.pumpWidget(auditApp(child: const EditProfileView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  return controller;
}

RegisterGradientButton _saveButton(WidgetTester tester) =>
    tester.widget<RegisterGradientButton>(find.widgetWithText(RegisterGradientButton, 'save_changes'.tr));

void main() {
  setUpAll(loadAuditFonts);

  testWidgets('the save bar counts unsaved changes and enables saving only when there are some', (tester) async {
    final c = await _pumpEditProfile(tester);
    expect(c.pendingChangesCount.value, 0);
    expect(find.text('لا توجد تغييرات'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    c.firstNameController.text = 'عمر';
    await tester.pump();
    expect(c.pendingChangesCount.value, 1);
    expect(find.text('تغيير واحد غير محفوظ'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNotNull);

    c.setGender('female');
    await tester.pump();
    expect(find.text('تغييران غير محفوظين'), findsOneWidget);

    c.toggleCategoryId(4);
    await tester.pump();
    expect(find.text(pluralTr('unsaved_changes', 3)), findsOneWidget);

    // التراجع عن تعديل يُنقص العدد بدل أن يبقى «متغيّراً».
    c.firstNameController.text = 'عبد الرحمن';
    c.setGender('male');
    c.toggleCategoryId(4);
    await tester.pump();
    expect(c.pendingChangesCount.value, 0);
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('first and last name share one row', (tester) async {
    await _pumpEditProfile(tester);
    final first = tester.getRect(find.widgetWithText(RegisterFloatingField, 'first_name_label'.tr));
    final last = tester.getRect(find.widgetWithText(RegisterFloatingField, 'last_name_label'.tr));
    expect(first.top, last.top);
    expect(first.height, last.height);
    expect(first.right, greaterThan(last.right)); // RTL: الاسم الأول أولاً من اليمين
  });

  testWidgets('sections are flat white cards with a 1px border', (tester) async {
    await _pumpEditProfile(tester);
    for (final title in ['personal_info'.tr, 'academic_info'.tr, 'account_settings'.tr]) {
      final box = tester.widget<DecoratedBox>(
        find.ancestor(of: find.text(title), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, Colors.white, reason: title);
      expect(decoration.boxShadow, isNull, reason: title);
      expect((decoration.border as Border).top.width, 1, reason: title);
    }
  });

  testWidgets('the account section shows phone and email with verification badges', (tester) async {
    final c = await _pumpEditProfile(tester);
    expect(find.text('0999123456'), findsOneWidget);
    // الجلسة الوهمية: الهاتف غير موثّق، والبريد موثّق.
    expect(find.text('غير موثّق'), findsOneWidget);
    expect(Get.find<TokenStorage>().phoneVerified.value, isFalse);
    expect(c.email.value, isNull);
    expect(find.text('email_not_set'.tr), findsOneWidget);

    c.email.value = 'student@mail.com';
    await tester.pump();
    expect(find.text('student@mail.com'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
  });

  testWidgets('interests stay a compact horizontal slider with a summary', (tester) async {
    final c = await _pumpEditProfile(tester);
    expect(c.selectedCategoryIds.length, 2);
    expect(find.text(pluralTr('interests_selected_count', 2)), findsOneWidget);

    final slider = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal);
    expect(slider, findsOneWidget);
    expect(tester.getSize(slider).height, 36);

    await tester.tap(find.byTooltip('interests_remove'.tr).first);
    await tester.pump();
    expect(c.selectedCategoryIds.length, 1);
    expect(c.pendingChangesCount.value, 1);
  });
}
