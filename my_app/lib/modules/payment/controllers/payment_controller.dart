import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/payment_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_refresh.dart';
import '../../../core/utils/app_toast.dart';

class PaymentController extends GetxController with InitialLoadState, SettledLoad {
  /// [enrollmentId] اختياري للاختبارات؛ في التطبيق يأتي رقم التسجيل (أو التسجيل نفسه) من arguments.
  PaymentController({int? enrollmentId}) : _forcedEnrollmentId = enrollmentId;

  final int? _forcedEnrollmentId;

  final PaymentRepository _repository = Get.find();

  static const _cooldownSeconds = 60;
  static final _transactionIdPattern = RegExp(r'^\d{1,20}$');

  late final int enrollmentId;
  int? courseId;

  final details = Rxn<PaymentDetailsModel>();
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final isSubmitting = false.obs;
  final fieldError = RxnString();
  final cooldown = 0.obs;
  final transactionController = TextEditingController();

  Timer? _cooldownTimer;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (_forcedEnrollmentId != null) {
      enrollmentId = _forcedEnrollmentId;
    } else if (arg is EnrollmentModel) {
      enrollmentId = arg.id;
      courseId = arg.courseId;
    } else {
      enrollmentId = arg is int ? arg : int.tryParse('$arg') ?? 0;
    }
    afterRouteSettles(load);
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    transactionController.dispose();
    super.onClose();
  }

  /// يُجلب من جديد عند كل فتح/سحب: المعهد قد يغيّر حساب شام كاش، فلا نخزّن العنوان.
  Future<void> load() async {
    if (enrollmentId <= 0) {
      errorMessage.value = 'error_unexpected'.tr;
      isLoading.value = false;
      return;
    }
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    try {
      details.value = await _repository.fetchDetails(enrollmentId);
      markLoaded();
    } on ApiCancelledException {
      return;
    } catch (e) {
      final message = e is ApiException ? _messageForStatus(e) : userErrorMessage(e);
      if (details.value == null) {
        errorMessage.value = message;
      } else {
        AppToast.show('error'.tr, message);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyAddress() async {
    final address = details.value?.shamcash.address;
    if (address == null) return;
    await Clipboard.setData(ClipboardData(text: address));
    AppToast.show(
      'payment_copied_title'.tr,
      'payment_copied_msg'.tr,
      duration: const Duration(seconds: 2),
      kind: ToastKind.success,
    );
  }

  Future<void> submit() async {
    if (isSubmitting.value || cooldown.value > 0) return;
    final transactionId = transactionController.text.trim();
    if (!_transactionIdPattern.hasMatch(transactionId)) {
      fieldError.value = 'payment_txn_invalid'.tr;
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    fieldError.value = null;
    isSubmitting.value = true;
    try {
      final result = await _repository.submitShamCash(enrollmentId, transactionId);
      transactionController.clear();
      AppToast.show('payment_success_title'.tr, 'payment_success_msg'.tr, kind: ToastKind.success);
      courseId ??= result.enrollment?.courseId;
      unawaited(SessionRefresh.afterEnrollmentStatusChanged(courseId: courseId, enrollmentId: enrollmentId));
      await load();
    } on ApiException catch (e) {
      _handleSubmitError(e);
    } catch (_) {
      AppToast.show('error'.tr, 'error_unexpected'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _handleSubmitError(ApiException e) {
    switch (e.statusCode) {
      case 422:
        fieldError.value = _rejectionMessage(e);
      case 429:
        _startCooldown();
        AppToast.show('error'.tr, 'payment_error_rate_limit'.tr);
      default:
        AppToast.show('error'.tr, _messageForStatus(e));
    }
  }

  void _startCooldown() {
    cooldown.value = _cooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldown.value <= 1) {
        cooldown.value = 0;
        timer.cancel();
      } else {
        cooldown.value--;
      }
    });
  }

  String _messageForStatus(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'payment_error_session'.tr;
      case 403:
        return 'payment_error_forbidden'.tr;
      case 404:
        return 'payment_error_not_found'.tr;
      case 429:
        return 'payment_error_rate_limit'.tr;
      case 503:
        return 'payment_error_unreachable'.tr;
      default:
        return e.message;
    }
  }

  /// رفض التحويل (422): الخادم يرسل `code` ثابتاً ورسالة بلغة التطبيق. نصوصنا للرموز المعروفة،
  /// ورسالة الخادم كما هي لغيرها.
  String _rejectionMessage(ApiException e) {
    const byCode = <String, String>{
      'invalid_transaction_id': 'payment_txn_invalid',
      'enrollment_closed': 'payment_err_closed',
      'already_paid': 'payment_err_already_paid',
      'free_course': 'payment_err_free',
      'shamcash_unavailable': 'payment_err_unavailable',
      'transaction_already_used': 'payment_err_used',
      'transfer_not_found': 'payment_err_not_found',
      'wrong_currency': 'payment_err_currency',
      'transfer_no_amount': 'payment_err_no_amount',
      'transfer_before_enrollment': 'payment_err_before_enroll',
    };
    final key = byCode[e.code];
    if (key != null) return key.tr;
    return e.fieldErrors?['transaction_id'] ?? e.message;
  }
}
