import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/payment_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_refresh.dart';

class PaymentController extends GetxController with InitialLoadState {
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
    load();
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
        Get.snackbar('error'.tr, message);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyAddress() async {
    final address = details.value?.shamcash.address;
    if (address == null) return;
    await Clipboard.setData(ClipboardData(text: address));
    Get.snackbar('payment_copied_title'.tr, 'payment_copied_msg'.tr, duration: const Duration(seconds: 2));
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
      Get.snackbar('payment_success_title'.tr, 'payment_success_msg'.tr);
      courseId ??= result.enrollment?.courseId;
      unawaited(SessionRefresh.afterEnrollmentStatusChanged(courseId: courseId, enrollmentId: enrollmentId));
      await load();
    } on ApiException catch (e) {
      _handleSubmitError(e);
    } catch (_) {
      Get.snackbar('error'.tr, 'error_unexpected'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _handleSubmitError(ApiException e) {
    switch (e.statusCode) {
      case 422:
        fieldError.value = _translateRejection(e.fieldErrors?['transaction_id'] ?? e.message);
      case 429:
        _startCooldown();
        Get.snackbar('error'.tr, 'payment_error_rate_limit'.tr);
      default:
        Get.snackbar('error'.tr, _messageForStatus(e));
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

  /// رسائل الرفض (422) تأتي بالإنجليزية دائماً — نترجم المعروف منها ونُبقي غيره كما هو.
  String _translateRejection(String message) {
    final m = message.toLowerCase();
    const rules = <String, String>{
      'already been used': 'payment_err_used',
      'no transfer with this transaction': 'payment_err_not_found',
      'must be made in syp': 'payment_err_currency',
      'before you enrolled': 'payment_err_before_enroll',
      'already paid': 'payment_err_already_paid',
      'is free': 'payment_err_free',
      'not available for this course': 'payment_err_unavailable',
      'no longer be paid': 'payment_err_closed',
      'has no amount': 'payment_err_no_amount',
      'is required': 'payment_txn_invalid',
      'format is invalid': 'payment_txn_invalid',
    };
    for (final rule in rules.entries) {
      if (m.contains(rule.key)) return rule.value.tr;
    }
    return message;
  }
}
