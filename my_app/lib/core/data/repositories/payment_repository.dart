import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';

/// دفع التسجيلات عبر شام كاش — التطبيق لا يتصل بشام كاش مباشرة، فقط بخادم Coursy.
class PaymentRepository extends GetxService {
  PaymentRepository(this._client);

  final ApiClient _client;

  Map<String, dynamic> _objectBody(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is Map && !map.containsKey('enrollment_id') && !map.containsKey('payment')) {
        return Map<String, dynamic>.from(data);
      }
      return map;
    }
    throw ApiException('error_invalid_server_response'.tr);
  }

  /// يُستدعى عند كل فتح للشاشة — لا يُخزَّن العنوان لأن المعهد قد يغيّر حسابه.
  Future<PaymentDetailsModel> fetchDetails(int enrollmentId) {
    return _client.handle(
      () => _client.get(ApiEndpoints.studentEnrollmentPayment(enrollmentId)),
      (body) => PaymentDetailsModel.fromJson(_objectBody(body)),
    );
  }

  Future<ShamCashSubmitResult> submitShamCash(int enrollmentId, String transactionId) {
    return _client.handle(
      () => _client.post(ApiEndpoints.studentEnrollmentShamCash(enrollmentId), data: {'transaction_id': transactionId}),
      (body) => ShamCashSubmitResult.fromJson(_objectBody(body)),
    );
  }
}
