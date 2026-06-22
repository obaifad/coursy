import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/bindings/root_binding.dart';
import '../controllers/my_courses_controller.dart';
import 'my_courses_tab_view.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/profile_avatar.dart';
import '../controllers/profile_controller.dart';

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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                        final controller = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
                        return ProfileAvatar(
                          size: 88,
                          imageUrl: controller?.displayAvatarUrl ?? storage.userAvatarUrl.value,
                          localPath: controller?.displayAvatarLocalPath ?? storage.userAvatarLocalPath.value,
                          onTap: storage.isLoggedIn
                              ? () {
                                  ProfileController.ensureRegistered();
                                  Get.find<ProfileController>().pickAvatar();
                                }
                              : null,
                        );
                      }),
                      const SizedBox(height: 14),
                      Obx(
                        () {
                          final storage = Get.find<TokenStorage>();
                          if (!storage.isLoggedIn) {
                            return Text(
                              'guest_user'.tr,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            );
                          }
                          return Text(
                            storage.userName.value ?? 'student'.tr,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () {
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
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, -4))],
                  ),
                  child: Obx(() {
                    if (!Get.find<TokenStorage>().isLoggedIn) {
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Get.toNamed(AppRoutes.login),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('login'.tr),
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
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final loggedIn = Get.find<TokenStorage>().isLoggedIn;
            if (!loggedIn) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
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
                ProfileMenuTile(
                  title: 'logout'.tr,
                  icon: Icons.logout_rounded,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _confirmAndLogout(context),
                ),
              ],
            );
          }),
        ),
        SizedBox(height: AppLayout.rootNavReserve(context) + 12),
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
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          child: Text('confirm'.tr),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  if (confirmed != true) return;
  await Get.find<AuthRepository>().logout();
  AppNavigation.enterAsGuest();
}

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('profile_edit'.tr),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: RegisterDecor.background),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppDetailSkeleton();
            }
            return AppMaxWidth(
              maxWidth: ResponsiveModals.dialogMaxWidth(context),
              child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + context.keyboardInset),
              children: [
                const _EditProfileAvatar(),
                const SizedBox(height: 20),
                RegisterFloatingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EditSectionTitle(title: 'personal_info'.tr, icon: Icons.person_outline_rounded),
                      const SizedBox(height: 14),
                      RegisterFloatingField(
                        controller: controller.firstNameController,
                        label: 'first_name_label'.tr,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      RegisterFloatingField(
                        controller: controller.lastNameController,
                        label: 'last_name_label'.tr,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      RegisterFloatingField(
                        controller: controller.phoneController,
                        label: 'phone'.tr,
                        readOnly: true,
                        prefixIcon: Icons.phone_android_rounded,
                        suffixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 12),
                      Text('gender'.tr, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 13)),
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
                      const SizedBox(height: 12),
                      Obx(
                        () => RegisterDateField(
                          label: 'birth_date'.tr,
                          value: controller.birthDate.value == null
                              ? null
                              : _formatDate(controller.birthDate.value!),
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
                          items: controller.cities
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => controller.selectedCityId.value = v,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                RegisterFloatingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EditSectionTitle(title: 'academic_info'.tr, icon: Icons.school_outlined),
                      const SizedBox(height: 14),
                      Obx(
                        () => _ProfileDropdown<String>(
                          label: 'education_level_optional'.tr,
                          icon: Icons.school_outlined,
                          value: controller.selectedEducationLevel.value,
                          hint: 'education_level_hint'.tr,
                          items: ProfileController.educationLevels
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(controller.educationLevelLabel(e)),
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
                              items: controller.universities
                                  .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                                  .toList(),
                              onChanged: (v) => controller.selectedUniversityId.value = v,
                            ),
                            const SizedBox(height: 12),
                            _ProfileDropdown<int>(
                              label: 'specialization_optional'.tr,
                              icon: Icons.workspace_premium_outlined,
                              value: controller.selectedSpecializationId.value,
                              hint: 'pick_specialization'.tr,
                              items: controller.specializations
                                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                                  .toList(),
                              onChanged: (v) => controller.selectedSpecializationId.value = v,
                            ),
                          ],
                        );
                      }),
                      Obx(() {
                        if (controller.categories.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RegisterInterestPicker(
                            categories: controller.categories,
                            selectedIds: controller.selectedCategoryIds.toList(),
                            onApply: controller.setCategoryIds,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            );
          }),
        ),
        bottomNavigationBar: Obx(
          () {
            controller.hasChanges.value;
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowSoft.withValues(alpha: 0.8),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: RegisterGradientButton(
                  label: 'save_changes'.tr,
                  loading: controller.isSaving.value,
                  success: controller.saveSucceeded.value,
                  onPressed: controller.isSaving.value ||
                          controller.saveSucceeded.value ||
                          !controller.hasChanges.value
                      ? null
                      : controller.saveProfile,
                ),
              ),
            );
          },
        ),
      ),
    );
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
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSectionTitle extends StatelessWidget {
  const _EditSectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  }
}

class _ProfileDropdown<T> extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: RegisterDecor.fieldDecoration(
        label: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      hint: Text(hint, style: GoogleFonts.tajawal()),
      items: items,
      onChanged: onChanged,
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
    return const Scaffold(
      body: MyCoursesTabView(),
    );
  }
}

class SettingsView extends GetView<LocaleController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: AppMaxWidth(
        child: ListView(
        padding: const EdgeInsets.all(16),
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
            child: SwitchListTile(
              value: true,
              onChanged: (v) {},
              title: Text('notifications_setting'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              children: [
                Obx(
                  () => ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                    title: Text('language'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(
                      controller.languageLabel,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    onTap: controller.showLanguagePicker,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: Text('privacy_policy'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Get.to(
                    () => _SettingsDocumentView(
                      title: 'privacy_policy'.tr,
                      body: 'privacy_policy_body'.tr,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: Text('about_app'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Get.to(
                    () => _SettingsDocumentView(
                      title: 'about_app'.tr,
                      body: 'about_app_body'.tr,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
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
          padding: const EdgeInsets.all(20),
          children: [
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                body,
                style: GoogleFonts.tajawal(fontSize: 15, height: 1.65, color: const Color(0xFF1F2937)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
