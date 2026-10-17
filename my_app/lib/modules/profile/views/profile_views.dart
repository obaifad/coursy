import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_fonts.dart';
import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/config/app_flags.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/session/session_refresh.dart';
import '../../../core/bindings/root_binding.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/external_launcher.dart';
import '../controllers/my_courses_controller.dart';
import 'my_courses_tab_view.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../widgets/app_select_field.dart';
import '../../../widgets/app_selection_sheet.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/profile_avatar.dart';
import '../controllers/profile_controller.dart';
import '../../../widgets/interest_picker_sheet.dart';
import '../../../widgets/app_widgets.dart';
import '../../../core/models/app_models.dart';
import '../../../core/locale/plural.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MyCoursesController>()) {
      RootBinding().dependencies();
    }
    return Obx(() {
      final _ = localeRebuildToken;
      return ListView(
        key: const PageStorageKey('profile_tab'),
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        Obx(() {
                          ProfileController.ensureRegistered();
                          final storage = Get.find<TokenStorage>();
                          final controller = Get.isRegistered<ProfileController>()
                              ? Get.find<ProfileController>()
                              : null;
                          return ProfileAvatar(
                            size: 88,
                            imageUrl: controller?.displayAvatarUrl ?? storage.userAvatarUrl.value,
                            localPath: controller?.displayAvatarLocalPath,
                            onTap: storage.isLoggedIn
                                ? () {
                                    ProfileController.ensureRegistered();
                                    Get.find<ProfileController>().pickAvatar();
                                  }
                                : null,
                          );
                        }),
                        const SizedBox(height: 14),
                        Obx(() {
                          final storage = Get.find<TokenStorage>();
                          if (!storage.isLoggedIn) {
                            return Text(
                              'guest_user'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppTextSize.xxl,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          }
                          return Text(
                            storage.userName.value ?? 'student'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppTextSize.xxl,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Obx(() {
                          final storage = Get.find<TokenStorage>();
                          if (!storage.isLoggedIn) {
                            return Text(
                              'guest_mode_subtitle'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            );
                          }
                          final phone = storage.userPhone.value;
                          return Text(
                            phone != null && phone.isNotEmpty ? phone : 'student'.tr,
                            style: const TextStyle(color: Colors.white70),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.readableInset(context), vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                      boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, -4))],
                    ),
                    child: Obx(() {
                      if (!Get.find<TokenStorage>().isLoggedIn) {
                        return SizedBox(
                          width: double.infinity,
                          child: RegisterGradientButton(
                            label: 'login'.tr,
                            onPressed: () => Get.toNamed(AppRoutes.login),
                          ),
                        );
                      }
                      final mc = Get.find<MyCoursesController>();
                      return AppStatsRow(
                        items: [
                          AppStatItem(value: '${mc.confirmed.length}', label: 'stat_active'.tr),
                          AppStatItem(value: '${mc.completed.length}', label: 'stat_completed'.tr),
                          AppStatItem(value: '${mc.pending.length}', label: 'stat_review'.tr),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.readableInset(context), vertical: 16),
            child: Obx(() {
              final storage = Get.find<TokenStorage>();
              final settings = ProfileMenuTile(
                title: 'settings'.tr,
                icon: Icons.settings_outlined,
                onTap: () => Get.toNamed(AppRoutes.settings),
              );
              if (!storage.isLoggedIn) {
                return Column(
                  children: [
                    ProfileMenuTile(
                      title: 'register'.tr,
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: () => Get.toNamed(AppRoutes.register),
                    ),
                    settings,
                  ],
                );
              }
              // يظهر فقط إن أكّد الخادم أن الرقم غير مُتحقَّق منه (null = غير معروف → لا نزعج المستخدم).
              final needsPhoneVerification = AppFlags.phoneVerificationEnabled && storage.phoneVerified.value == false;
              // نفس المبدأ: يظهر فقط حين يؤكد الخادم أن البريد غير مؤكد.
              final needsEmailVerification = AppFlags.emailVerificationEnabled && storage.emailVerified.value == false;
              return Column(
                children: [
                  if (needsEmailVerification)
                    ProfileMenuTile(
                      title: 'verify_email_title'.tr,
                      icon: Icons.mark_email_unread_outlined,
                      onTap: () => Get.toNamed(AppRoutes.emailVerification),
                    ),
                  if (needsPhoneVerification)
                    ProfileMenuTile(
                      title: 'verify_phone_title'.tr,
                      icon: Icons.verified_user_outlined,
                      onTap: () => Get.toNamed(AppRoutes.phoneVerification, arguments: storage.userPhone.value),
                    ),
                  ProfileMenuTile(
                    title: 'profile_edit'.tr,
                    icon: Icons.edit_outlined,
                    onTap: () => Get.toNamed(AppRoutes.editProfile),
                  ),
                  ProfileMenuTile(
                    title: 'favorites_title'.tr,
                    icon: Icons.favorite_rounded,
                    onTap: () => Get.toNamed(AppRoutes.favorites),
                  ),
                  ProfileMenuTile(
                    title: 'my_courses'.tr,
                    icon: Icons.menu_book_outlined,
                    onTap: () => AppNavigation.switchToTab(3),
                  ),
                  settings,
                  ProfileMenuTile(
                    title: 'logout'.tr,
                    icon: Icons.logout_rounded,
                    destructive: true,
                    trailing: const SizedBox.shrink(),
                    onTap: () => _confirmAndLogout(context),
                  ),
                ],
              );
            }),
          ),
          SizedBox(height: AppLayout.scrollBottomInset(context, rootTab: true)),
        ],
      );
    });
  }
}

Future<void> _confirmAndLogout(BuildContext context) async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: Text('logout_confirm_title'.tr),
      content: Text('logout_confirm_message'.tr),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
          onPressed: () => Get.back(result: true),
          child: Text('confirm'.tr),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  if (confirmed != true) return;
  await SessionRefresh.onLogout();
  await Get.find<AuthRepository>().logout();
  AppNavigation.enterAsGuest();
  SessionRefresh.reloadAsGuest();
}

/// تعديل الملف الشخصي (شريط هادئ): أقسام بيضاء مسطّحة بحدّ 1px — المعلومات الشخصية، الأكاديمية،
/// والحساب (الهاتف والبريد بشارات التحقق) — وشريط حفظ ثابت أسفل الشاشة يعدّ التغييرات غير المحفوظة.
class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('profile_edit'.tr),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        final _ = localeRebuildToken;
        return AppMaxWidth(
          maxWidth: ResponsiveModals.dialogMaxWidth(context),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + context.keyboardInset),
            children: [
              const _EditProfileAvatar(),
              const SizedBox(height: 20),
              _ProfileSection(
                title: 'personal_info'.tr,
                icon: Icons.person_outline_rounded,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RegisterFloatingField(
                          controller: controller.firstNameController,
                          label: 'first_name_label'.tr,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RegisterFloatingField(
                          controller: controller.lastNameController,
                          label: 'last_name_label'.tr,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('gender'.tr, style: AppTypography.filterSectionLabel()),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      children: [
                        RegisterChoiceChip(
                          label: 'male'.tr,
                          selected: controller.selectedGender.value == 'male',
                          onTap: () => controller.setGender('male'),
                        ),
                        RegisterChoiceChip(
                          label: 'female'.tr,
                          selected: controller.selectedGender.value == 'female',
                          onTap: () => controller.setGender('female'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => RegisterDateField(
                      label: 'birth_date'.tr,
                      value: controller.birthDate.value == null ? null : _formatDate(controller.birthDate.value!),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: controller.birthDate.value ?? DateTime(now.year - 20),
                          firstDate: DateTime(1950),
                          lastDate: now,
                        );
                        if (picked != null) controller.birthDate.value = picked;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _ProfileDropdown<int>(
                      label: 'city'.tr,
                      icon: Icons.location_city_rounded,
                      value: controller.selectedCityId.value,
                      hint: 'pick_city'.tr,
                      options: controller.cities
                          .map(
                            (c) => AppSheetOption<int>(value: c.id, label: c.name, icon: Icons.location_city_rounded),
                          )
                          .toList(),
                      onChanged: (v) => controller.selectedCityId.value = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProfileSection(
                title: 'academic_info'.tr,
                icon: Icons.school_outlined,
                children: [
                  Obx(
                    () => _ProfileDropdown<String>(
                      label: 'education_level_optional'.tr,
                      icon: Icons.school_outlined,
                      value: controller.selectedEducationLevel.value,
                      hint: 'education_level_hint'.tr,
                      options: ProfileController.educationLevels
                          .map(
                            (e) => AppSheetOption<String>(
                              value: e,
                              label: controller.educationLevelLabel(e),
                              icon: Icons.school_outlined,
                            ),
                          )
                          .toList(),
                      onChanged: controller.setEducationLevel,
                    ),
                  ),
                  Obx(() {
                    if (!controller.requiresUniversityFields) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        _ProfileDropdown<int>(
                          label: 'university_optional'.tr,
                          icon: Icons.account_balance_rounded,
                          value: controller.selectedUniversityId.value,
                          hint: 'pick_university'.tr,
                          options: controller.universities
                              .map(
                                (u) => AppSheetOption<int>(
                                  value: u.id,
                                  label: u.name,
                                  icon: Icons.account_balance_rounded,
                                ),
                              )
                              .toList(),
                          onChanged: (v) => controller.selectedUniversityId.value = v,
                        ),
                        const SizedBox(height: 12),
                        _ProfileDropdown<int>(
                          label: 'specialization_optional'.tr,
                          icon: Icons.workspace_premium_outlined,
                          value: controller.selectedSpecializationId.value,
                          hint: 'pick_specialization'.tr,
                          options: controller.specializations
                              .map(
                                (s) => AppSheetOption<int>(
                                  value: s.id,
                                  label: s.name,
                                  icon: Icons.workspace_premium_outlined,
                                ),
                              )
                              .toList(),
                          onChanged: (v) => controller.selectedSpecializationId.value = v,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  const _InterestsControl(),
                ],
              ),
              const SizedBox(height: 12),
              _ProfileSection(
                title: 'account_settings'.tr,
                icon: Icons.manage_accounts_outlined,
                children: const [_AccountDetails()],
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: const _UnsavedChangesBar(),
    );
  }
}

/// قسم مسطّح: بطاقة بيضاء بحدّ 1px وعنوان بأيقونة.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppCorners.md,
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppTypography.sectionTitle())),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// الاهتمامات بشكل مضغوط: سطر ملخّص («3 اهتمامات محددة») وزر تعديل يفتح ورقة الاختيار، وتحته شريط
/// شرائح أفقي قابل للتمرير بالمحدد منها (لكلٍّ زر إزالة) — بدل جدار شرائح عمودي طويل.
class _InterestsControl extends GetView<ProfileController> {
  const _InterestsControl();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.categories.toList(growable: false);
      final selectedIds = controller.selectedCategoryIds.toList(growable: false);
      final loading = controller.listsLoading.value;
      final selected = [for (final id in selectedIds) ?categories.firstWhereOrNull((c) => c.id == id)];
      final summary = selectedIds.isEmpty
          ? 'pick_interests'.tr
          : pluralTr('interests_selected_count', selectedIds.length);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.interests_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('interests_optional'.tr, style: AppTypography.filterSectionLabel()),
                    const SizedBox(height: 2),
                    Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.cardSubtitle()),
                  ],
                ),
              ),
              if (categories.isNotEmpty && !loading)
                TextButton.icon(
                  onPressed: () => showInterestPickerSheet(
                    context: context,
                    categories: categories,
                    initialSelected: selectedIds.toSet(),
                    onApply: (ids) => controller.setCategoryIds(ids.toList()),
                  ),
                  icon: Icon(selectedIds.isEmpty ? Icons.add_rounded : Icons.edit_outlined, size: 18),
                  label: Text(selectedIds.isEmpty ? 'interests_add'.tr : 'interests_edit'.tr),
                ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: AppInlineLoader(size: 20)),
            )
          else if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: RegisterGhostButton(
                label: 'reload_interests'.tr,
                onPressed: () => controller.loadLists(force: true),
              ),
            )
          else if (selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selected.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) =>
                    _InterestChip(category: selected[i], onRemove: () => controller.toggleCategoryId(selected[i].id)),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.category, required this.onRemove});

  final CategoryModel category;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.indicatorFill, borderRadius: AppCorners.full),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryIcon(category: category, size: 24, borderRadius: AppCorners.full),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: AppFonts.tajawal(
                fontSize: AppTextSize.sm,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryInk,
              ),
            ),
            IconButton(
              tooltip: 'interests_remove'.tr,
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryInk),
            ),
          ],
        ),
      ),
    );
  }
}

/// الهاتف والبريد (للقراءة فقط) بشارة التحقق؛ «تحقّق الآن» حين يؤكد الخادم أنهما غير موثّقين.
class _AccountDetails extends GetView<ProfileController> {
  const _AccountDetails();

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<TokenStorage>();
    return Obx(() {
      final phoneVerified = storage.phoneVerified.value;
      final emailVerified = storage.emailVerified.value;
      final email = controller.email.value;
      return Column(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.phoneController,
            builder: (context, phone, _) => _AccountRow(
              icon: Icons.phone_android_rounded,
              label: 'phone'.tr,
              value: phone.text.trim().isEmpty ? '—' : phone.text.trim(),
              ltrValue: true,
              verified: phoneVerified,
              onVerify: AppFlags.phoneVerificationEnabled && phoneVerified == false
                  ? () => Get.toNamed(AppRoutes.phoneVerification, arguments: storage.userPhone.value)
                  : null,
            ),
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.borderNeutral),
          _AccountRow(
            icon: Icons.alternate_email_rounded,
            label: 'email'.tr,
            value: email ?? 'email_not_set'.tr,
            ltrValue: email != null,
            verified: email == null ? null : emailVerified,
            onVerify: AppFlags.emailVerificationEnabled && email != null && emailVerified == false
                ? () => Get.toNamed(AppRoutes.emailVerification)
                : null,
          ),
        ],
      );
    });
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.verified,
    this.ltrValue = false,
    this.onVerify,
  });

  final IconData icon;
  final String label;
  final String value;

  /// true/false من الخادم، null = غير معروف (لا شارة).
  final bool? verified;

  /// رقم هاتف أو بريد: يُعرض من اليسار لليمين حتى داخل الواجهة العربية.
  final bool ltrValue;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: AppColors.indicatorFill, borderRadius: AppCorners.sm),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption()),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: ltrValue ? TextDirection.ltr : null,
                style: AppFonts.tajawal(
                  fontSize: AppTextSize.md,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (verified != null) ...[const SizedBox(width: 8), _VerificationBadge(verified: verified!)],
        if (onVerify != null) ...[
          const SizedBox(width: 4),
          TextButton(
            onPressed: onVerify,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('verify_now'.tr),
          ),
        ],
      ],
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final fg = verified ? AppColors.successText : AppColors.warningText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: verified ? AppColors.successSoft : AppColors.warningFill,
        borderRadius: AppCorners.full,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(verified ? Icons.verified_rounded : Icons.error_outline_rounded, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(verified ? 'verified_badge'.tr : 'not_verified_badge'.tr, style: AppTypography.caption(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// شريط الحفظ الثابت: عدد التغييرات غير المحفوظة من المتحكّم، وزر الحفظ يتفعّل فقط حين يوجد تغيير.
class _UnsavedChangesBar extends GetView<ProfileController> {
  const _UnsavedChangesBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final count = controller.pendingChangesCount.value;
      final saving = controller.isSaving.value;
      final saved = controller.saveSucceeded.value;
      final dirty = count > 0;
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.borderNeutral)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(
                  dirty ? Icons.edit_note_rounded : Icons.check_circle_outline_rounded,
                  size: 20,
                  color: dirty ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dirty ? pluralTr('unsaved_changes', count) : 'no_unsaved_changes'.tr,
                    maxLines: 2,
                    style: AppFonts.tajawal(
                      fontSize: AppTextSize.sm,
                      fontWeight: dirty ? FontWeight.w700 : FontWeight.w500,
                      color: dirty ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 132, maxWidth: 200),
                  child: RegisterGradientButton(
                    label: 'save_changes'.tr,
                    loading: saving,
                    success: saved,
                    onPressed: saving || saved || !dirty ? null : controller.saveProfile,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _EditProfileAvatar extends GetView<ProfileController> {
  const _EditProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Center(
        child: Column(
          children: [
            ProfileAvatar(
              size: 92,
              imageUrl: controller.displayAvatarUrl,
              localPath: controller.displayAvatarLocalPath,
              onTap: controller.pickAvatar,
              showCameraBadge: true,
            ),
            const SizedBox(height: 10),
            Text(
              'tap_to_change_photo'.tr,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppTextSize.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDropdown<T> extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final String hint;
  final List<AppSheetOption<T>> options;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSelectField<T>(
      label: label,
      icon: icon,
      hint: hint,
      value: value,
      options: options,
      enabled: onChanged != null,
      onChanged: (v) => onChanged?.call(v),
    );
  }
}

String _formatDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class MyCoursesView extends GetView<MyCoursesController> {
  const MyCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: MyCoursesTabView());
  }
}

class SettingsView extends GetView<LocaleController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        appBar: AppBar(title: Text('settings'.tr)),
        body: AppMaxWidth(
          child: ListView(
            // آخر صف («حذف الحساب») لا يختفي خلف شريط التنقّل (Android 15+ يرسم التطبيق حتى حافة الشاشة).
            padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
            children: [
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    const AppLogo(height: 52, alignment: Alignment.center),
                    const SizedBox(height: 10),
                    Text('app_tagline'.tr, style: AppTypography.pageSubtitle(), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: kIsWeb
                    ? SwitchListTile(
                        value: false,
                        onChanged: null,
                        title: Text('notifications_setting'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('notifications_web_unavailable'.tr),
                      )
                    : Obx(() {
                        final push = Get.find<PushNotificationService>();
                        final enabled = push.notificationsEnabled.value;
                        final permitted = push.notificationsPermissionGranted.value;
                        String subtitle;
                        if (!enabled) {
                          subtitle = 'notifications_setting_off'.tr;
                        } else if (!permitted) {
                          subtitle = 'notifications_permission_denied'.tr;
                        } else {
                          subtitle = 'notifications_setting_on'.tr;
                        }
                        return SwitchListTile(
                          value: enabled && permitted,
                          onChanged: push.isToggling.value ? null : push.setNotificationsEnabled,
                          title: Text('notifications_setting'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(subtitle),
                        );
                      }),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  children: [
                    Obx(
                      () => ListTile(
                        leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                        title: Text('language'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text(
                          controller.languageLabel,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        onTap: () => controller.showLanguagePicker(context),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                      title: Text('privacy_policy'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
                      onTap: () => ExternalLauncher.openWebPage(ApiConfig.privacyUrl(controller.code.value)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                      title: Text('terms_of_use'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
                      onTap: () => ExternalLauncher.openWebPage(ApiConfig.termsUrl(controller.code.value)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                      title: Text('contact_us'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
                      onTap: () => ExternalLauncher.openWebPage(ApiConfig.contactUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      title: Text('about_app'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      onTap: () =>
                          Get.to(() => _SettingsDocumentView(title: 'about_app'.tr, body: 'about_app_body'.tr)),
                    ),
                  ],
                ),
              ),
              if (Get.find<TokenStorage>().isLoggedIn) ...[
                const SizedBox(height: 16),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                    title: Text(
                      'delete_account'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                    onTap: () => Get.toNamed(AppRoutes.deleteAccount),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _SettingsDocumentView extends StatelessWidget {
  const _SettingsDocumentView({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppMaxWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, AppLayout.scrollBottomInset(context)),
          children: [
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                body,
                style: AppFonts.tajawal(fontSize: AppTextSize.lg, height: 1.65, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
