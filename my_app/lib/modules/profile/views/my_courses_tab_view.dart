import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/plural.dart';

import '../../../theme/app_fonts.dart';
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

  /// رأس العلامة ينطوي مع التمرير وتبويبات الحالة تبقى مثبّتة تحته؛ الرأس يمتد تحت شريط الحالة بنفسه.
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          Obx(
            () => AppBrandSliverAppBar(
              title: 'my_courses'.tr,
              subtitle: 'my_courses_subtitle'.tr,
              badge: controller.enrollments.isEmpty ? null : pluralTr('bookings_count', controller.enrollments.length),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(AppTabBarSection.sectionHeight + 6),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AppTabBarSection(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'tab_pending'.tr),
                      Tab(text: 'tab_confirmed'.tr),
                      Tab(text: 'tab_done'.tr),
                      Tab(text: 'tab_cancelled'.tr),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Obx(
          () => controller.isLoading.value
              ? AppRowListSkeleton(itemCount: 4, padding: AppLayout.scrollPadding(context, rootTab: true, top: 8))
              : TabBarView(
                  controller: _tabController,
                  physics: const ClampingScrollPhysics(),
                  children: const [
                    _EnrollmentList(status: _EnrollmentListStatus.pending),
                    _EnrollmentList(status: _EnrollmentListStatus.confirmed),
                    _EnrollmentList(status: _EnrollmentListStatus.completed),
                    _EnrollmentList(status: _EnrollmentListStatus.cancelled),
                  ],
                ),
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
      final error = controller.errorMessage.value;
      // بلا اتصال: رسالة الخطأ مع «إعادة المحاولة» بدل «لا حجوزات».
      if (items.isEmpty && controller.enrollments.isEmpty && error != null) {
        return RefreshIndicator(
          onRefresh: controller.load,
          color: AppColors.primary,
          child: AppEmptyState.scrollable(
            context: context,
            message: error,
            icon: Icons.cloud_off_outlined,
            action: FilledButton(onPressed: controller.load, child: Text('retry'.tr)),
          ),
        );
      }
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
          itemBuilder: (_, i) => _EnrollmentCard(enrollment: items[i], controller: controller),
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

    final institute = course?.institute.trim() ?? '';

    // بطاقة صفّية: الصورة، العنوان وشارة الحالة، المعهد، سطر البيانات؛ وتحتها أزرار الحجز.
    return AppRowCard(
      onTap: () => _openCourseDetails(enrollment),
      leading: _CourseThumb(imagePath: course?.imageUrl),
      title: AppRowTitle(enrollment.courseTitle ?? course?.title ?? 'course_details'.tr),
      trailing: _StatusBadge(theme: theme, label: enrollment.statusLabel),
      subtitle: institute.isEmpty ? null : AppRowMeta(icon: Icons.apartment_rounded, text: institute),
      footer: meta.isNotEmpty
          ? AppRowMetaLine(
              items: [for (final m in meta.rows.take(2)) AppRowMeta(icon: m.icon, text: m.label)],
            )
          : null,
      below: _BookingActions(
        enrollment: enrollment,
        controller: controller,
        onDetails: () => _openCourseDetails(enrollment),
        onCancel: () => _confirmCancel(context, enrollment),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('cancel_booking'.tr, style: AppFonts.tajawal(fontWeight: FontWeight.w800)),
        content: Text('cancel_booking_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
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
    // المقاس والزوايا من AppRowCard.
    final url = ApiConfig.resolveMediaUrl(imagePath);
    return url != null
        ? AppNetworkImage(url: url, fit: BoxFit.cover, ignorePointer: true)
        : const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.cardPlaceholder),
            child: Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 32)),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.foregroundColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(theme.icon, size: 14, color: theme.foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w700,
              color: theme.foregroundColor,
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

  /// الدورات التي تُدفع حضورياً في المعهد: «غير مدفوع» تقلق الطالب بلا داعٍ، فلا تظهر إلا إن وُجد دفع.
  static bool _showsPaymentStatus(EnrollmentModel e) {
    final status = e.paymentStatus.toLowerCase();
    if (status.isEmpty) return false;
    return e.course?.requiresAdvancePayment == true || status == 'paid' || status == 'partial';
  }

  /// سطر البطاقة الصفّية بتسميات قصيرة: أهم معلومة (الدفع، ثم موعد البدء، ثم الجدول) ورقم الحجز.
  final List<_MetaRow> rows;

  bool get isNotEmpty => rows.isNotEmpty;

  factory _EnrollmentMeta.from(EnrollmentModel enrollment) {
    final course = enrollment.course;
    final rows = <_MetaRow>[
      if (_showsPaymentStatus(enrollment))
        _MetaRow(icon: Icons.payments_outlined, label: JsonHelpers.paymentStatusLabel(enrollment.paymentStatus))
      else if (course?.startDate != null)
        _MetaRow(icon: Icons.event_rounded, label: JsonHelpers.formatDisplayDate(course!.startDate))
      else if (course != null && course.schedules.isNotEmpty)
        _MetaRow(
          icon: Icons.schedule_rounded,
          label: '${JsonHelpers.weekdayLabel(course.schedules.first.dayOfWeek)} · ${course.schedules.first.startTime}',
        ),
      _MetaRow(icon: Icons.confirmation_number_outlined, label: '#${enrollment.id}'),
    ];
    return _EnrollmentMeta(rows);
  }
}

/// أزرار بطاقة الحجز في صف واحد مضغوط:
/// الإجراء الأساسي (ادفع الآن إن أمكن، وإلا عرض التفاصيل) ممتلئ بالبنفسجي،
/// والثانوي (عرض التفاصيل) بحد خفيف، وإلغاء الحجز زر صغير بحد أحمر خفيف.
class _BookingActions extends StatelessWidget {
  const _BookingActions({
    required this.enrollment,
    required this.controller,
    required this.onDetails,
    required this.onCancel,
  });

  final EnrollmentModel enrollment;
  final MyCoursesController controller;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  static const double _height = 44;

  ButtonStyle _outlined(Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color.withValues(alpha: 0.4)),
    minimumSize: const Size(0, _height),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
  );

  @override
  Widget build(BuildContext context) {
    final canCancel = enrollment.canCancel;
    final label = AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.sm);

    return Obx(() {
      // «ادفع الآن» فقط إذا كان الدفع الإلكتروني متاحاً فعلاً؛ وإلا «عرض التفاصيل» هو الإجراء الأساسي.
      controller.paymentAvailable.length;
      final canPay = controller.showPayButton(enrollment);
      return _buildRow(canPay, canCancel, label);
    });
  }

  Widget _buildRow(bool canPay, bool canCancel, TextStyle label) {
    // يصغر النص بدل قصّه: «عرض التفاصيل» كان يظهر «عرض التفاصـ…» بجانب «ادفع الآن» على هاتف 1080px.
    Widget fitted(String text) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, style: label, maxLines: 1),
    );
    final details = canPay
        ? OutlinedButton(onPressed: onDetails, style: _outlined(AppColors.primary), child: fitted('view_details'.tr))
        : SizedBox(
            height: _height,
            child: RegisterGradientButton(label: 'view_details'.tr, onPressed: onDetails),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // عرضان متساويان: «عرض التفاصيل» أطول من «ادفع الآن»، وكانت حصته 2 من 5 فقط.
        if (canPay)
          Expanded(
            child: SizedBox(
              height: _height,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.payment, arguments: enrollment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStrong,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                label: fitted('payment_pay_now'.tr),
              ),
            ),
          ),
        if (canPay) const SizedBox(width: 8),
        Expanded(child: details),
        if (canCancel) ...[
          const SizedBox(width: 8),
          Obx(() {
            controller.cancellingIds.length;
            final cancelling = controller.cancellingIds.contains(enrollment.id);
            return Tooltip(
              message: 'cancel_booking'.tr,
              child: OutlinedButton(
                onPressed: cancelling ? null : onCancel,
                style: _outlined(AppColors.danger).copyWith(
                  minimumSize: const WidgetStatePropertyAll(Size(_height, _height)),
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                child: cancelling ? const AppInlineLoader() : const Icon(Icons.close_rounded, size: 20),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _EnrollmentStatusTheme {
  const _EnrollmentStatusTheme({required this.backgroundColor, required this.foregroundColor, required this.icon});

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  static const pending = _EnrollmentStatusTheme(
    backgroundColor: AppColors.warningFill,
    foregroundColor: AppColors.warning,
    icon: Icons.hourglass_top_rounded,
  );

  static const confirmed = _EnrollmentStatusTheme(
    backgroundColor: AppColors.successFill,
    foregroundColor: AppColors.successStrong,
    icon: Icons.check_circle_outline_rounded,
  );

  static const completed = _EnrollmentStatusTheme(
    backgroundColor: AppColors.infoSoft,
    foregroundColor: AppColors.info,
    icon: Icons.school_outlined,
  );

  static const cancelled = _EnrollmentStatusTheme(
    backgroundColor: AppColors.dangerSoft,
    foregroundColor: AppColors.danger,
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
    final title = switch (status) {
      _EnrollmentListStatus.pending => 'my_courses_empty_title_pending'.tr,
      _EnrollmentListStatus.confirmed => 'my_courses_empty_title_confirmed'.tr,
      _EnrollmentListStatus.completed => 'my_courses_empty_title_completed'.tr,
      _EnrollmentListStatus.cancelled => 'my_courses_empty_title_cancelled'.tr,
    };
    final message = switch (status) {
      _EnrollmentListStatus.pending => 'my_courses_empty_pending'.tr,
      _EnrollmentListStatus.confirmed => 'my_courses_empty_confirmed'.tr,
      _EnrollmentListStatus.completed => 'my_courses_empty_completed'.tr,
      _EnrollmentListStatus.cancelled => 'my_courses_empty_cancelled'.tr,
    };
    // كل التبويبات الفارغة تقود إلى خطوة تالية — لا شاشة بلا مخرج.
    return AppEmptyState(
      message: title,
      subtitle: message,
      icon: theme.icon,
      iconColor: AppColors.primary,
      iconBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
      action: SizedBox(
        width: 220,
        child: RegisterGradientButton(label: 'browse_courses'.tr, onPressed: () => AppNavigation.switchToTab(0)),
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: RegisterDecor.cardShadow,
                ),
                child: Column(
                  children: [
                    const AppLogo(height: 44),
                    const SizedBox(height: 20),
                    Text('login_to_see_courses'.tr, textAlign: TextAlign.center, style: AppTypography.sectionTitle()),
                    const SizedBox(height: 20),
                    RegisterGradientButton(label: 'login'.tr, onPressed: () => Get.toNamed(AppRoutes.login)),
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
