import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import 'register_form_widgets.dart';

/// يُرجع أخطاء الحقول (`email` / `current_password`) أو null عند النجاح.
typedef ChangeEmailSubmit = Future<Map<String, String>?> Function(String email, String currentPassword);

/// ورقة تعديل البريد (البريد الجديد + كلمة المرور الحالية). true إن حُفظ البريد.
Future<bool> showChangeEmailSheet(
  BuildContext context, {
  required String initialEmail,
  required ChangeEmailSubmit onSubmit,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => ChangeEmailSheet(initialEmail: initialEmail, onSubmit: onSubmit),
  );
  return saved == true;
}

/// الورقة تملك حقولها وتتخلّص منها في dispose — أي بعد انتهاء حركة الإغلاق. (التخلّص منها فور عودة
/// showModalBottomSheet كان يرمي «TextEditingController was used after being disposed» أثناء الإغلاق.)
class ChangeEmailSheet extends StatefulWidget {
  const ChangeEmailSheet({super.key, required this.initialEmail, required this.onSubmit});

  final String initialEmail;
  final ChangeEmailSubmit onSubmit;

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  Map<String, String> _errors = const {};
  bool _hidePassword = true;
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _errors = const {};
    });
    final errors = await widget.onSubmit(_email.text, _password.text);
    if (!mounted) return;
    if (errors == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _errors = errors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'edit_email_title'.tr,
            style: AppFonts.tajawal(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'edit_email_hint'.tr,
            style: AppFonts.tajawal(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            autofocus: true,
            enabled: !_saving,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'email'.tr,
              errorText: _errors['email'],
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            enabled: !_saving,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'current_password'.tr,
              errorText: _errors['current_password'],
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: 'toggle_password_visibility'.tr,
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          RegisterGradientButton(label: 'save_and_send_code'.tr, loading: _saving, onPressed: _saving ? null : _submit),
        ],
      ),
    );
  }
}
