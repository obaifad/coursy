import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../auth/widgets/register_form_widgets.dart';
import '../controllers/payment_controller.dart';

String _money(double value, String currency) {
  final unit = currency.toUpperCase() == 'SYP' ? 'currency_syp'.tr : currency;
  return '${JsonHelpers.groupThousands(value.round())} $unit';
}

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final data = controller.details.value;
      return Scaffold(
        appBar: AppBar(title: Text('payment_title'.tr)),
        body: AppMaxWidth(
          child: data == null
              ? (controller.isLoading.value
                    ? const AppListSkeleton(itemCount: 3)
                    : _PaymentError(message: controller.errorMessage.value ?? 'error_unexpected'.tr))
              : RefreshIndicator(
                  onRefresh: controller.load,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
                    children: [
                      _SummaryCard(data: data),
                      const SizedBox(height: 16),
                      if (data.isPaid)
                        const _PaidCard()
                      else if (data.shamcash.canPay) ...[
                        _TransferCard(data: data),
                        const SizedBox(height: 16),
                        const _SubmitCard(),
                      ] else
                        _UnavailableCard(
                          advanceRequired: data.advanceRequiredButUnavailable,
                          onlineCourse: data.shamcash.isOnlineCourse,
                        ),
                      if (data.payments.isNotEmpty) ...[const SizedBox(height: 16), _HistoryCard(data: data)],
                      const _BottomAction(),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}

class _PaymentError extends GetView<PaymentController> {
  const _PaymentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      message: message,
      icon: Icons.error_outline_rounded,
      action: SizedBox(
        width: 200,
        child: RegisterGradientButton(label: 'retry'.tr, onPressed: controller.load),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final PaymentDetailsModel data;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (data.paymentStatus) {
      'paid' => ('payment_status_paid'.tr, AppColors.successSoft, AppColors.successText),
      'partial' => ('payment_status_partial'.tr, AppColors.warningFill, AppColors.warning),
      _ => ('payment_status_unpaid'.tr, AppColors.dangerSoft, AppColors.dangerText),
    };
    return _PayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              // العنوان والحالة في سطر واحد حين يتسعان، وإلا تنزل الحالة تحت العنوان — بدل أن ينكسر
              // «Payment summary» إلى سطرين بجانبها على هاتف 360.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text('payment_summary'.tr, style: AppTypography.sectionTitle()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: AppFonts.tajawal(color: fg, fontWeight: FontWeight.w700, fontSize: AppTextSize.xs),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AmountRow(label: 'payment_amount_due'.tr, value: _money(data.amountDue, data.currency)),
          if (data.advanceAmount > 0)
            _AmountRow(label: 'payment_advance'.tr, value: _money(data.advanceAmount, data.currency)),
          _AmountRow(label: 'payment_paid'.tr, value: _money(data.amountPaid, data.currency)),
          if (data.hasPendingAdvance && !data.isPaid)
            _AmountRow(
              label: 'payment_remaining_at_institute'.tr,
              value: _money(data.remainingAtInstitute, data.currency),
            ),
          const SizedBox(height: 10),
          // المبلغ الأهم الآن: المطلوب الآن (الدفعة المقدّمة) إن وُجدت، وإلا المتبقي.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (data.hasPendingAdvance ? 'payment_required_now' : 'payment_remaining').tr,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextSize.md,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
                Text(
                  _money(data.amountToSendNow, data.currency),
                  style: AppFonts.tajawal(
                    fontWeight: FontWeight.w800,
                    fontSize: AppTextSize.xxl,
                    color: AppColors.primaryInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة موحّدة لصفحة الدفع: خلفية بيضاء، حد خفيف، ظل ناعم، زوايا 20.
class _PayCard extends StatelessWidget {
  const _PayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowPrimary, blurRadius: 20, offset: Offset(0, 8)),
          BoxShadow(color: AppColors.shadowNeutralSoft, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

/// صندوق معلومات: خلفية مصبوغة خفيفة، أيقونة، عنوان ونص.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
  static const Color tint = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tint.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: AppTextSize.lg, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppFonts.tajawal(fontSize: AppTextSize.sm, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.tajawal(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: AppTextSize.md,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppFonts.tajawal(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: AppTextSize.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends GetView<PaymentController> {
  const _TransferCard({required this.data});

  final PaymentDetailsModel data;

  @override
  Widget build(BuildContext context) {
    final shamcash = data.shamcash;
    final qr = shamcash.qrPayload;
    return _PayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('payment_shamcash_title'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 4),
          Text('payment_steps'.tr, style: AppTypography.cardSubtitle(size: AppTextSize.sm).copyWith(height: 1.5)),
          if (shamcash.accountName != null) ...[
            const SizedBox(height: 14),
            Text(
              'payment_account_name'.tr,
              style: AppFonts.tajawal(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: AppTextSize.xs,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              shamcash.accountName!,
              style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: AppTextSize.lg),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'payment_address'.tr,
            style: AppFonts.tajawal(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: AppTextSize.xs,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    shamcash.address!,
                    style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: AppTextSize.lg, letterSpacing: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: controller.copyAddress,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text('payment_copy'.tr),
              ),
            ],
          ),
          if (qr != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderNeutral),
                ),
                child: QrImageView(data: qr, size: 180, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'payment_scan_qr'.tr,
              textAlign: TextAlign.center,
              style: AppFonts.tajawal(
                color: AppColors.textSecondary,
                fontSize: AppTextSize.xs,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmitCard extends GetView<PaymentController> {
  const _SubmitCard();

  @override
  Widget build(BuildContext context) {
    return _PayCard(
      child: Obx(() {
        final waiting = controller.cooldown.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('payment_txn_title'.tr, style: AppTypography.sectionTitle()),
            const SizedBox(height: 4),
            Text('payment_txn_help'.tr, style: AppTypography.cardSubtitle(size: AppTextSize.sm).copyWith(height: 1.5)),
            const SizedBox(height: 12),
            TextField(
              controller: controller.transactionController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(20)],
              onChanged: (_) => controller.fieldError.value = null,
              onSubmitted: (_) => controller.submit(),
              decoration: RegisterDecor.fieldDecoration(
                label: 'payment_txn_label'.tr,
                hint: 'payment_txn_hint'.tr,
                errorText: controller.fieldError.value,
                prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            RegisterGradientButton(
              label: waiting > 0 ? 'payment_wait'.trParams({'seconds': '$waiting'}) : 'payment_submit'.tr,
              loading: controller.isSubmitting.value,
              onPressed: waiting > 0 || controller.isSubmitting.value ? null : controller.submit,
            ),
          ],
        );
      }),
    );
  }
}

class _PaidCard extends StatelessWidget {
  const _PaidCard();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      compact: true,
      message: 'payment_fully_paid'.tr,
      subtitle: 'payment_fully_paid_hint'.tr,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      iconBackgroundColor: AppColors.successSoft,
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.advanceRequired, this.onlineCourse = false});

  /// الدورة تتطلب دفعة مقدّمة لكن حساب شام كاش غير مفعّل لدى المعهد.
  final bool advanceRequired;

  /// دورة أونلاين: تُدفع للمعهد مباشرة، لا داخل التطبيق.
  final bool onlineCourse;

  @override
  Widget build(BuildContext context) {
    if (onlineCourse) {
      return _InfoBanner(
        icon: Icons.storefront_rounded,
        title: 'payment_online_direct'.tr,
        body: 'payment_online_direct_hint'.tr,
      );
    }
    return _InfoBanner(
      icon: advanceRequired ? Icons.link_off_rounded : Icons.storefront_rounded,
      title: (advanceRequired ? 'payment_shamcash_not_connected' : 'payment_unavailable').tr,
      body: (advanceRequired ? 'payment_shamcash_not_connected_hint' : 'payment_unavailable_hint').tr,
    );
  }
}

/// إجراء سفلي يُكمل الرحلة: العودة إلى تفاصيل الدورة (بحد خفيف حتى لا ينافس الإجراء الأساسي).
class _BottomAction extends GetView<PaymentController> {
  const _BottomAction();

  @override
  Widget build(BuildContext context) {
    final courseId = controller.courseId;
    if (courseId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: () => Get.toNamed(AppRoutes.courseDetails, arguments: courseId),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.primaryInk,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        label: Text(
          'view_details'.tr,
          style: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.md),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.data});

  final PaymentDetailsModel data;

  @override
  Widget build(BuildContext context) {
    return _PayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('payment_history'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 8),
          for (final p in data.payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _money(p.amount, p.currency),
                          style: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.md),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '#${p.transactionId}',
                            style: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: AppTextSize.xs),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.occurredAt != null)
                    Text(
                      JsonHelpers.formatDisplayDate(p.occurredAt!.toIso8601String()),
                      style: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: AppTextSize.xs),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
