import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/storage/token_storage.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../core/bindings/root_binding.dart';
import '../controllers/my_courses_controller.dart';

class MyCoursesTabView extends GetView<MyCoursesController> {
  const MyCoursesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MyCoursesController>()) {
      RootBinding().dependencies();
    }
    return Obx(() {
      final _ = localeRebuildToken;
      if (!Get.find<TokenStorage>().isLoggedIn) {
        return const _MyCoursesLoginPrompt();
      }
      if (controller.isLoading.value) {
        return const AppListSkeleton(itemCount: 5);
      }
      return _MyCoursesShell(controller: controller);
    });
  }
}

class _MyCoursesShell extends StatefulWidget {
  const _MyCoursesShell({required this.controller});

  final MyCoursesController controller;

  @override
  State<_MyCoursesShell> createState() => _MyCoursesShellState();
}

class _MyCoursesShellState extends State<_MyCoursesShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  MyCoursesController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppScreenHeader(
              title: 'my_courses'.tr,
              subtitle: 'my_courses_subtitle'.tr,
              logoInline: true,
              logoHeight: 44,
            ),
            AppTabBarSection(
              controller: _tabController,
              tabs: [
                Tab(text: 'tab_pending'.tr),
                Tab(text: 'tab_confirmed'.tr),
                Tab(text: 'tab_done'.tr),
                Tab(text: 'tab_cancelled'.tr),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  _EnrollmentList(status: _EnrollmentListStatus.pending),
                  _EnrollmentList(status: _EnrollmentListStatus.confirmed),
                  _EnrollmentList(status: _EnrollmentListStatus.completed),
                  _EnrollmentList(status: _EnrollmentListStatus.cancelled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _EnrollmentListStatus { pending, confirmed, completed, cancelled }

class _EnrollmentList extends GetView<MyCoursesController> {
  const _EnrollmentList({required this.status});

  final _EnrollmentListStatus status;

  List<EnrollmentModel> _itemsForStatus() {
    switch (status) {
      case _EnrollmentListStatus.pending:
        return controller.pending;
      case _EnrollmentListStatus.confirmed:
        return controller.confirmed;
      case _EnrollmentListStatus.completed:
        return controller.completed;
      case _EnrollmentListStatus.cancelled:
        return controller.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _itemsForStatus();
      if (items.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.load,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppLayout.scrollPadding(context, rootTab: true, top: 8),
            children: [_MyCoursesEmptyState(status: status)],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        color: AppColors.primary,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppLayout.scrollPadding(context, rootTab: true, top: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _EnrollmentCard(
            enrollment: items[i],
            controller: controller,
          ),
        ),
      );
    });
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.enrollment, required this.controller});

  final EnrollmentModel enrollment;
  final MyCoursesController controller;

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course;
    final theme = _EnrollmentStatusTheme.fromStatus(enrollment.status);
    final meta = _EnrollmentMeta.from(enrollment);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x126C63FF), blurRadius: 20, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CourseThumb(imagePath: course?.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.courseTitle ?? course?.title ?? 'course_details'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.25,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      if (course?.institute.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          course!.institute,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(theme: theme, label: enrollment.statusLabel),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in meta.rows) _MetaChip(icon: m.icon, label: m.label),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (enrollment.canCancel) ...[
                  Expanded(
                    child: Obx(() {
                      controller.cancellingIds.length;
                      final isCancelling = controller.cancellingIds.contains(enrollment.id);
                      return OutlinedButton.icon(
                        onPressed: isCancelling ? null : () => _confirmCancel(context, enrollment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: isCancelling
                            ? const AppInlineLoader()
                            : const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          isCancelling ? 'saving'.tr : 'cancel_booking'.tr,
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: enrollment.canCancel ? 1 : 2,
                  child: RegisterGradientButton(
                    label: 'view_details'.tr,
                    onPressed: () => _openCourseDetails(enrollment),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCourseDetails(EnrollmentModel enrollment) {
    final course = enrollment.course;
    if (course != null) {
      Get.toNamed(AppRoutes.courseDetails, arguments: course);
    } else if (enrollment.courseId != null) {
      Get.toNamed(AppRoutes.courseDetails, arguments: enrollment.courseId);
    }
  }

  Future<void> _confirmCancel(BuildContext context, EnrollmentModel enrollment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('cancel_booking'.tr, style: GoogleFonts.tajawal(fontWeight: FontWeight.w800)),
        content: Text('cancel_booking_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancelEnrollment(enrollment);
    }
  }
}

class _CourseThumb extends StatelessWidget {
  const _CourseThumb({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.resolveMediaUrl(imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url != null
            ? AppNetworkImage(url: url, fit: BoxFit.cover, ignorePointer: true)
            : Container(
                decoration: const BoxDecoration(gradient: AppGradients.cardPlaceholder),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.theme, required this.label});

  final _EnrollmentStatusTheme theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.foregroundColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(theme.icon, size: 14, color: theme.foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow {
  const _MetaRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _EnrollmentMeta {
  const _EnrollmentMeta(this.rows);

  final List<_MetaRow> rows;

  bool get isNotEmpty => rows.isNotEmpty;

  factory _EnrollmentMeta.from(EnrollmentModel enrollment) {
    final course = enrollment.course;
    final rows = <_MetaRow>[
      _MetaRow(icon: Icons.confirmation_number_outlined, label: '${'booking_id'.tr} #${enrollment.id}'),
      if (enrollment.paymentStatus.isNotEmpty)
        _MetaRow(icon: Icons.payments_outlined, label: '${'payment_status'.tr}: ${enrollment.paymentStatus}'),
      if (course?.instructor?.name.isNotEmpty == true)
        _MetaRow(icon: Icons.person_outline_rounded, label: course!.instructor!.name),
      if (course?.startDate != null)
        _MetaRow(
          icon: Icons.event_rounded,
          label: '${'starts_on'.tr}: ${JsonHelpers.formatDisplayDate(course!.startDate)}',
        ),
      if (course != null && course.schedules.isNotEmpty)
        _MetaRow(
          icon: Icons.schedule_rounded,
          label: '${JsonHelpers.weekdayLabel(course.schedules.first.dayOfWeek)} · ${course.schedules.first.startTime}',
        ),
    ];
    return _EnrollmentMeta(rows);
  }
}

class _EnrollmentStatusTheme {
  const _EnrollmentStatusTheme({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  static const pending = _EnrollmentStatusTheme(
    backgroundColor: Color(0xFFFEF3C7),
    foregroundColor: Color(0xFFD97706),
    icon: Icons.hourglass_top_rounded,
  );

  static const confirmed = _EnrollmentStatusTheme(
    backgroundColor: Color(0xFFD1FAE5),
    foregroundColor: Color(0xFF059669),
    icon: Icons.check_circle_outline_rounded,
  );

  static const completed = _EnrollmentStatusTheme(
    backgroundColor: Color(0xFFDBEAFE),
    foregroundColor: Color(0xFF2563EB),
    icon: Icons.school_outlined,
  );

  static const cancelled = _EnrollmentStatusTheme(
    backgroundColor: Color(0xFFFEE2E2),
    foregroundColor: Color(0xFFDC2626),
    icon: Icons.cancel_outlined,
  );

  static _EnrollmentStatusTheme fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
        return confirmed;
      case 'completed':
        return completed;
      case 'cancelled':
      case 'rejected':
        return cancelled;
      case 'pending':
      default:
        return pending;
    }
  }
}

class _MyCoursesEmptyState extends StatelessWidget {
  const _MyCoursesEmptyState({required this.status});

  final _EnrollmentListStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = switch (status) {
      _EnrollmentListStatus.pending => _EnrollmentStatusTheme.pending,
      _EnrollmentListStatus.confirmed => _EnrollmentStatusTheme.confirmed,
      _EnrollmentListStatus.completed => _EnrollmentStatusTheme.completed,
      _EnrollmentListStatus.cancelled => _EnrollmentStatusTheme.cancelled,
    };
    final message = switch (status) {
      _EnrollmentListStatus.pending => 'my_courses_empty_pending'.tr,
      _EnrollmentListStatus.confirmed => 'my_courses_empty_confirmed'.tr,
      _EnrollmentListStatus.completed => 'my_courses_empty_completed'.tr,
      _EnrollmentListStatus.cancelled => 'my_courses_empty_cancelled'.tr,
    };
    final showBrowse = status == _EnrollmentListStatus.pending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(theme.icon, size: 40, color: theme.foregroundColor),
          ),
          const SizedBox(height: 20),
          Text(
            'my_courses_empty_title'.tr,
            style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (showBrowse) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: RegisterGradientButton(
                label: 'browse_courses'.tr,
                onPressed: () => AppNavigation.switchToTab(0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyCoursesLoginPrompt extends StatelessWidget {
  const _MyCoursesLoginPrompt();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: RegisterDecor.cardShadow,
                ),
                child: Column(
                  children: [
                    const AppLogo(height: 44),
                    const SizedBox(height: 20),
                    Text(
                      'login_to_see_courses'.tr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    RegisterGradientButton(
                      label: 'login'.tr,
                      onPressed: () => Get.toNamed(AppRoutes.login),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
