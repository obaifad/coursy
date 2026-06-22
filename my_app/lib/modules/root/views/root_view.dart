import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/design_system.dart';
import '../../courses/views/courses_views.dart';
import '../../home/views/home_view.dart';
import '../../institutes/views/institutes_views.dart';
import '../../profile/views/my_courses_tab_view.dart';
import '../../profile/views/profile_views.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/storage/token_storage.dart';
import '../controllers/root_controller.dart';

class RootView extends GetView<RootController> {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    AppNavigation.ensureRootBinding();
    const screens = [
      CoursesView(),
      InstitutesView(),
      HomeView(),
      MyCoursesTabView(),
      ProfileView(),
    ];

    return Obx(
      () => PopScope(
        canPop: controller.currentIndex.value == 2,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && controller.currentIndex.value != 2) {
            controller.changeTab(2);
          }
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: AppColors.surface,
          body: PageStorage(
            bucket: controller.pageStorageBucket,
            child: IndexedStack(index: controller.currentIndex.value, children: screens),
          ),
          bottomNavigationBar: _RootBottomNav(
            currentIndex: controller.currentIndex.value,
            onChanged: controller.changeTab,
          ),
        ),
      ),
    );
  }
}

class _RootBottomNav extends StatelessWidget {
  const _RootBottomNav({required this.currentIndex, required this.onChanged});

  static const double _centerSlotWidth = 58;

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<TokenStorage>();
    return Obx(() {
      final _ = localeRebuildToken;
      final profileLabel = storage.isLoggedIn ? 'nav_profile'.tr : 'nav_login'.tr;
      final profileIcon = storage.isLoggedIn ? Icons.person_outline_rounded : Icons.login_rounded;
      final profileActiveIcon = storage.isLoggedIn ? Icons.person_rounded : Icons.login_rounded;

      final items = [
        _NavItem(
          icon: Icons.menu_book_outlined,
          activeIcon: Icons.menu_book_rounded,
          label: 'nav_courses'.tr,
          index: 0,
        ),
        _NavItem(
          icon: Icons.apartment_outlined,
          activeIcon: Icons.apartment_rounded,
          label: 'nav_institutes'.tr,
          index: 1,
        ),
        _NavItem(
          icon: Icons.home_rounded,
          activeIcon: Icons.home_rounded,
          label: 'nav_home'.tr,
          index: 2,
          center: true,
        ),
        _NavItem(
          icon: Icons.school_outlined,
          activeIcon: Icons.school_rounded,
          label: 'nav_my_courses'.tr,
          index: 3,
        ),
        _NavItem(
          icon: profileIcon,
          activeIcon: profileActiveIcon,
          label: profileLabel,
          index: 4,
        ),
      ];

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                boxShadow: const [
                  BoxShadow(color: Color(0x266C63FF), blurRadius: 28, offset: Offset(0, 12)),
                  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _SideNavButton(
                            selected: currentIndex == items[0].index,
                            icon: currentIndex == items[0].index ? items[0].activeIcon : items[0].icon,
                            label: items[0].label,
                            onTap: () => onChanged(items[0].index),
                          ),
                        ),
                        Expanded(
                          child: _SideNavButton(
                            selected: currentIndex == items[1].index,
                            icon: currentIndex == items[1].index ? items[1].activeIcon : items[1].icon,
                            label: items[1].label,
                            onTap: () => onChanged(items[1].index),
                          ),
                        ),
                        const SizedBox(width: _RootBottomNav._centerSlotWidth),
                        Expanded(
                          child: _SideNavButton(
                            selected: currentIndex == items[3].index,
                            icon: currentIndex == items[3].index ? items[3].activeIcon : items[3].icon,
                            label: items[3].label,
                            onTap: () => onChanged(items[3].index),
                          ),
                        ),
                        Expanded(
                          child: _SideNavButton(
                            selected: currentIndex == items[4].index,
                            icon: currentIndex == items[4].index ? items[4].activeIcon : items[4].icon,
                            label: items[4].label,
                            onTap: () => onChanged(items[4].index),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CenterNavButton(
                    selected: currentIndex == items[2].index,
                    icon: items[2].activeIcon,
                    onTap: () => onChanged(items[2].index),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _CenterNavButton extends StatelessWidget {
  const _CenterNavButton({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  static const double _size = 52;

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primary : null,
            color: selected ? null : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.primary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x446C63FF)
                    : const Color(0x14000000),
                blurRadius: selected ? 16 : 10,
                offset: Offset(0, selected ? 8 : 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: selected ? Colors.white : AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.primary : null,
                  color: selected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.center = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final bool center;
}
