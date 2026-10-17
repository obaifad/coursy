import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// حقل رمز تحقق بخانات منفصلة (6 افتراضياً).
///
/// خلف الخانات حقل نص حقيقي شفاف واحد: لوحة أرقام، لصق الرمز كاملاً، وملء تلقائي من رسالة
/// (oneTimeCode) — كلها تعمل دون منطق خاص لكل خانة. الأرقام تُرتَّب من اليسار لليمين حتى في العربية.
/// يهتز عند تغيّر [shakeTrigger] (خطأ في الرمز) ما لم تكن الحركة معطّلة في النظام.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.hasError = false,
    this.shakeTrigger = 0,
    this.enabled = true,
    this.autofocus = true,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final int shakeTrigger;
  final bool enabled;
  final bool autofocus;
  final String? semanticsLabel;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger && !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      textField: true,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([widget.controller, widget.focusNode]),
                builder: (context, _) => _Boxes(
                  text: widget.controller.text,
                  length: widget.length,
                  focused: widget.focusNode.hasFocus,
                  hasError: widget.hasError,
                  enabled: widget.enabled,
                ),
              ),
              // الحقل الحقيقي فوق الخانات وشفاف: الضغط على أي خانة يفتح لوحة الأرقام.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    showCursor: false,
                    maxLength: widget.length,
                    decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Boxes extends StatelessWidget {
  const _Boxes({
    required this.text,
    required this.length,
    required this.focused,
    required this.hasError,
    required this.enabled,
  });

  final String text;
  final int length;
  final bool focused;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // الخانة النشطة = أول خانة فارغة (أو الأخيرة إن اكتمل الرمز).
    final active = text.length >= length ? length - 1 : text.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final boxWidth = ((constraints.maxWidth - gap * (length - 1)) / length).clamp(36.0, 54.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _Box(
                width: boxWidth,
                digit: i < text.length ? text[i] : '',
                isActive: focused && enabled && i == active,
                hasError: hasError,
                enabled: enabled,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.digit,
    required this.isActive,
    required this.hasError,
    required this.enabled,
  });

  final double width;
  final String digit;
  final bool isActive;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final filled = digit.isNotEmpty;
    final Color border;
    final double borderWidth;
    if (hasError) {
      border = AppColors.danger;
      borderWidth = 1.6;
    } else if (isActive) {
      border = AppColors.primary;
      borderWidth = 2;
    } else if (filled) {
      border = AppColors.primary.withValues(alpha: 0.45);
      borderWidth = 1.4;
    } else {
      border = AppColors.borderNeutral;
      borderWidth = 1.2;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: width * 1.18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.dangerSoft.withValues(alpha: 0.5)
            : (isActive ? AppColors.card : AppColors.surfaceSoft),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: border, width: borderWidth),
        boxShadow: isActive && !hasError
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.16), blurRadius: 10, offset: const Offset(0, 4))]
            : const [],
      ),
      child: Text(
        digit,
        style: AppFonts.tajawal(
          fontSize: AppTextSize.xxl,
          fontWeight: FontWeight.w800,
          color: enabled ? AppColors.textPrimary : AppColors.textHint,
        ),
      ),
    );
  }
}
