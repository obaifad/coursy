import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/responsive/responsive.dart';
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
                        const _UnavailableCard(),
                      if (data.payments.isNotEmpty) ...[const SizedBox(height: 16), _HistoryCard(data: data)],
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
      _ => ('payment_status_unpaid'.tr, AppColors.neutralFill, AppColors.textMuted),
    };
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('payment_summary'.tr, style: AppTypography.sectionTitle())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  label,
                  style: AppFonts.tajawal(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AmountRow(label: 'payment_amount_due'.tr, value: _money(data.amountDue, data.currency)),
          if (data.advanceAmount > 0)
            _AmountRow(label: 'payment_advance'.tr, value: _money(data.advanceAmount, data.currency)),
          _AmountRow(label: 'payment_paid'.tr, value: _money(data.amountPaid, data.currency)),
          const Divider(height: 20),
          _AmountRow(label: 'payment_remaining'.tr, value: _money(data.amountRemaining, data.currency), bold: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w800 : FontWeight.w700;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.tajawal(color: AppColors.textSecondary, fontWeight: weight, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppFonts.tajawal(
                color: bold ? AppColors.primary : AppColors.textPrimary,
                fontWeight: weight,
                fontSize: bold ? 16 : 14,
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
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('payment_shamcash_title'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 4),
          Text('payment_steps'.tr, style: AppTypography.cardSubtitle(size: 13).copyWith(height: 1.5)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(
                  'payment_send_now'.tr,
                  style: AppFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(data.amountToSendNow, data.currency),
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ],
            ),
          ),
          if (shamcash.accountName != null) ...[
            const SizedBox(height: 14),
            Text(
              'payment_account_name'.tr,
              style: AppFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(shamcash.accountName!, style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15)),
          ],
          const SizedBox(height: 14),
          Text(
            'payment_address'.tr,
            style: AppFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    shamcash.address!,
                    style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderNeutral),
                ),
                child: QrImageView(data: qr, size: 180, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'payment_scan_qr'.tr,
              textAlign: TextAlign.center,
              style: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
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
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final waiting = controller.cooldown.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('payment_txn_title'.tr, style: AppTypography.sectionTitle()),
            const SizedBox(height: 4),
            Text('payment_txn_help'.tr, style: AppTypography.cardSubtitle(size: 13).copyWith(height: 1.5)),
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
  const _UnavailableCard();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      compact: true,
      message: 'payment_unavailable'.tr,
      subtitle: 'payment_unavailable_hint'.tr,
      icon: Icons.storefront_rounded,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.data});

  final PaymentDetailsModel data;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
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
                          style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '#${p.transactionId}',
                            style: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.occurredAt != null)
                    Text(
                      JsonHelpers.formatDisplayDate(p.occurredAt!.toIso8601String()),
                      style: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
