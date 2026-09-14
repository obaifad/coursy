import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/guest_access.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_split_layout.dart';
import '../widgets/login_page_metrics.dart';
import '../widgets/register_form_widgets.dart';
import '../../../widgets/design_system.dart';

final List<TextInputFormatter> _phoneInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<AuthController>()) return;
      Get.find<AuthController>().prepareRegisterReferenceData();
    });
  }

  AuthController get controller => Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final metrics = LoginPageMetrics.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor:
            metrics.useSplitLayout ? Colors.white : const Color(0xFFF6F5FF),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Obx(() {
            final _ = localeRebuildToken;
            final step = controller.registerStep.value;
            final loading = controller.isAdvancingStep.value || controller.isSubmittingRegister.value;
            final keyboardInset = context.keyboardInset;
            final bottomPad = keyboardInset > 0 ? keyboardInset + 16 : metrics.pageVerticalPadding + 16;

            final registerContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLogo(
                  height: metrics.logoHeight,
                  alignment: metrics.useSplitLayout
                      ? AlignmentDirectional.centerStart
                      : Alignment.center,
                ),
                SizedBox(height: metrics.sectionGap),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.previousRegisterStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: AppColors.shadowPurple,
                        elevation: metrics.useSplitLayout ? 0 : 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('register_title'.tr, style: RegisterDecor.heading(context)),
                          const SizedBox(height: 2),
                          Text(
                            'register_step'.trParams({'step': '${step + 1}'}),
                            style: RegisterDecor.subheading(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.sectionGap),
                RegisterSegmentedProgress(currentStep: step),
                if (controller.registerStepError.value != null &&
                    controller.registerStepError.value!.isNotEmpty) ...[
                  SizedBox(height: metrics.fieldGap),
                  _ErrorBanner(message: controller.registerStepError.value!),
                ],
                SizedBox(height: metrics.sectionGap),
                RegisterFloatingCard(
                  elevated: !metrics.useSplitLayout,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(step),
                      child: _RegisterStepBody(
                        step: step,
                        fieldGap: metrics.fieldGap,
                        nameFieldsInRow: metrics.useSplitLayout,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: metrics.sectionGap),
                Row(
                  children: [
                    if (step > 0) ...[
                      Expanded(
                        child: RegisterGhostButton(
                          label: 'previous'.tr,
                          onPressed: loading ? null : controller.previousRegisterStep,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: step > 0 ? 2 : 1,
                      child: RegisterGradientButton(
                        label: loading
                            ? (step < 2 ? 'validating'.tr : 'saving'.tr)
                            : step < 2
                                ? 'next'.tr
                                : 'create_account'.tr,
                        loading: loading,
                        onPressed: loading
                            ? null
                            : () {
                                if (step < 2) {
                                  controller.nextRegisterStep();
                                } else {
                                  controller.submitRegister();
                                }
                              },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.fieldGap),
                Center(child: _SignInLink()),
                const SizedBox(height: 8),
                Center(child: GuestContinueButton()),
              ],
            );

            if (metrics.useSplitLayout) {
              return AuthSplitLayout(
                metrics: metrics,
                heroVariant: AuthSplitHeroVariant.register,
                bottomInset: keyboardInset,
                form: registerContent,
              );
            }

            return DecoratedBox(
              decoration: const BoxDecoration(gradient: RegisterDecor.background),
              child: LayoutBuilder(
                builder: (context, viewport) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      metrics.horizontalPadding,
                      metrics.pageVerticalPadding + 16,
                      metrics.horizontalPadding,
                      bottomPad,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: viewport.maxHeight),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
                          child: registerContent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SignInLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('have_account_prefix'.tr, style: GoogleFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        TextButton(
          onPressed: () => Get.offNamed(AppRoutes.login),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'sign_in'.tr,
            style: GoogleFonts.tajawal(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.tajawal(color: Colors.red.shade700, fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterStepBody extends GetView<AuthController> {
  const _RegisterStepBody({
    required this.step,
    required this.fieldGap,
    this.nameFieldsInRow = false,
  });
  final int step;
  final double fieldGap;
  final bool nameFieldsInRow;

  String? _fieldError(String key) => controller.registerFieldErrors[key];

  InputDecoration _dropdownDecoration({
    required String label,
    String? errorText,
    IconData? icon,
  }) {
    return RegisterDecor.fieldDecoration(
      label: label,
      errorText: errorText,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return Column(
          children: [
            _RegisterNameFields(fieldGap: fieldGap, nameFieldsInRow: nameFieldsInRow),
            SizedBox(height: fieldGap),
            Obx(
              () => RegisterFloatingField(
                controller: controller.emailController,
                label: 'email_required'.tr,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.email_outlined,
                errorText: _fieldError('email'),
              ),
            ),
            SizedBox(height: fieldGap),
            Obx(
              () => RegisterFloatingField(
                controller: controller.phoneController,
                label: 'phone_required'.tr,
                hint: 'phone_hint'.tr,
                keyboardType: TextInputType.phone,
                inputFormatters: _phoneInputFormatters,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.phone_android_rounded,
                errorText: _fieldError('phone'),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => RegisterFloatingField(
                controller: controller.registerPasswordController,
                label: 'password_required'.tr,
                obscureText: controller.hideRegisterPassword.value,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outline_rounded,
                errorText: _fieldError('password'),
                suffixIcon: IconButton(
                  onPressed: () => controller.hideRegisterPassword.toggle(),
                  icon: Icon(
                    controller.hideRegisterPassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'password_must_have_letter_number'.tr,
              style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 14),
            Obx(
              () => RegisterFloatingField(
                controller: controller.confirmPasswordController,
                label: '${'confirm_password'.tr} *',
                obscureText: controller.hideConfirmPassword.value,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_reset_rounded,
                errorText: _fieldError('confirmPassword'),
                suffixIcon: IconButton(
                  onPressed: () => controller.hideConfirmPassword.toggle(),
                  icon: Icon(
                    controller.hideConfirmPassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('gender'.tr, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RegisterChoiceChip(
                    label: 'male'.tr,
                    selected: controller.selectedGender.value == 'male',
                    onTap: () => controller.selectedGender.value = 'male',
                  ),
                  RegisterChoiceChip(
                    label: 'female'.tr,
                    selected: controller.selectedGender.value == 'female',
                    onTap: () => controller.selectedGender.value = 'female',
                  ),
                ],
              ),
            ),
            if (_fieldError('gender') != null) ...[
              const SizedBox(height: 6),
              Text(
                _fieldError('gender')!,
                style: GoogleFonts.tajawal(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Obx(
              () => RegisterDateField(
                label: '${'birth_date'.tr} *',
                value: controller.birthDate.value == null
                    ? null
                    : AuthController.formatBirthDate(controller.birthDate.value!),
                errorText: _fieldError('birthDate'),
                onTap: () async {
                  final now = DateTime.now();
                  final maxBirthDate = DateTime(now.year - 10, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(now.year - 20),
                    firstDate: DateTime(1950),
                    lastDate: maxBirthDate,
                  );
                  if (picked != null) controller.birthDate.value = picked;
                },
              ),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'role_student'.tr,
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.citiesLoading.value && controller.cities.isEmpty) {
                return Skeletonizer(
                  enabled: true,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.indicatorFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
              if (controller.cities.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      controller.citiesError.value ?? 'connection_error'.tr,
                      style: GoogleFonts.tajawal(color: Colors.red.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    RegisterGhostButton(
                      label: 'reload_cities'.tr,
                      onPressed: () => controller.loadCities(force: true),
                    ),
                  ],
                );
              }
              final selectedId = controller.selectedCityId.value;
              final cityValue =
                  controller.cities.any((c) => c.id == selectedId) ? selectedId : null;
              return DropdownButtonFormField<int>(
                value: cityValue,
                isExpanded: true,
                decoration: _dropdownDecoration(
                  label: '${'city'.tr} *',
                  errorText: controller.citiesError.value ?? controller.registerFieldErrors['city'],
                  icon: Icons.location_city_outlined,
                ),
                hint: Text('pick_city'.tr, style: GoogleFonts.tajawal()),
                items: controller.cities
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: GoogleFonts.tajawal(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => controller.selectedCityId.value = v,
              );
            }),
            const SizedBox(height: 14),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedEducationLevel.value,
                isExpanded: true,
                decoration: _dropdownDecoration(
                  label: 'education_level_optional'.tr,
                  icon: Icons.school_outlined,
                ),
                hint: Text('education_level_hint'.tr, style: GoogleFonts.tajawal()),
                items: AuthController.educationLevels
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(controller.educationLevelLabel(e), style: GoogleFonts.tajawal()),
                      ),
                    )
                    .toList(),
                onChanged: controller.setEducationLevel,
              ),
            ),
            Obx(() {
              if (!controller.requiresUniversityFields) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Text('register_section_academic'.tr, style: RegisterDecor.sectionLabel()),
                  const SizedBox(height: 10),
                  if (controller.referencesLoading.value && controller.universities.isEmpty)
                    Skeletonizer(
                      enabled: true,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.indicatorFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: controller.selectedUniversityId.value,
                      isExpanded: true,
                      decoration: _dropdownDecoration(
                        label: 'university_optional'.tr,
                        errorText: controller.registerFieldErrors['university'],
                        icon: Icons.account_balance_rounded,
                      ),
                      hint: Text('pick_university'.tr, style: GoogleFonts.tajawal()),
                      items: controller.universities
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  u.name,
                                  style: GoogleFonts.tajawal(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => controller.selectedUniversityId.value = v,
                    ),
                  const SizedBox(height: 14),
                  if (controller.referencesLoading.value && controller.specializations.isEmpty)
                    Skeletonizer(
                      enabled: true,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.indicatorFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: controller.selectedSpecializationId.value,
                      isExpanded: true,
                      decoration: _dropdownDecoration(
                        label: 'specialization_optional'.tr,
                        errorText: controller.registerFieldErrors['specialization'],
                        icon: Icons.workspace_premium_outlined,
                      ),
                      hint: Text('pick_specialization'.tr, style: GoogleFonts.tajawal()),
                      items: controller.specializations
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  style: GoogleFonts.tajawal(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => controller.selectedSpecializationId.value = v,
                    ),
                ],
              );
            }),
            const SizedBox(height: 14),
            Obx(
              () => RegisterInterestPicker(
                categories: controller.categories,
                selectedIds: controller.selectedCategoryIds.toList(),
                loading: controller.categoriesLoading.value,
                errorText: controller.categoriesError.value ?? controller.registerFieldErrors['interests'],
                onReload: () => controller.loadCategories(force: true),
                onApply: controller.setCategoryIds,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'register_after_note'.tr,
              style: GoogleFonts.tajawal(color: AppColors.textSecondary, height: 1.45, fontSize: 13),
            ),
          ],
        );
    }
  }
}

class _RegisterNameFields extends GetView<AuthController> {
  const _RegisterNameFields({required this.fieldGap, this.nameFieldsInRow = false});
  final double fieldGap;
  final bool nameFieldsInRow;

  @override
  Widget build(BuildContext context) {
    final firstName = Obx(
      () => RegisterFloatingField(
        controller: controller.firstNameController,
        label: '${'first_name'.tr} *',
        textInputAction: TextInputAction.next,
        prefixIcon: Icons.person_outline_rounded,
        errorText: controller.registerFieldErrors['firstName'],
      ),
    );
    final lastName = Obx(
      () => RegisterFloatingField(
        controller: controller.lastNameController,
        label: '${'last_name'.tr} *',
        textInputAction: TextInputAction.next,
        prefixIcon: Icons.badge_outlined,
        errorText: controller.registerFieldErrors['lastName'],
      ),
    );

    if (nameFieldsInRow) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: firstName),
          SizedBox(width: fieldGap),
          Expanded(child: lastName),
        ],
      );
    }

    return Column(
      children: [
        firstName,
        SizedBox(height: fieldGap),
        lastName,
      ],
    );
  }
}
