import 'package:flutter_upi_india/flutter_upi_india.dart';

abstract class PaymentService {
  Future<List<ApplicationMeta>> getInstalledUpiApps();
  Future<UpiTransactionResponse> initiateUpiPayment({
    required UpiApplication app,
    required String amount,
    required String orderId,
  });
}

class UpiPaymentService implements PaymentService {
  final String receiverUpiId;
  final String receiverName;

  UpiPaymentService({
    this.receiverUpiId = 'merchant@upi',
    this.receiverName = 'Triveni Store',
  });

  @override
  Future<List<ApplicationMeta>> getInstalledUpiApps() async {
    return await UpiPay.getInstalledUpiApplications();
  }

  @override
  Future<UpiTransactionResponse> initiateUpiPayment({
    required UpiApplication app,
    required String amount,
    required String orderId,
  }) async {
    return await UpiPay.initiateTransaction(
      app: app,
      receiverUpiAddress: receiverUpiId,
      receiverName: receiverName,
      transactionRef: orderId,
      transactionNote: 'Order #${orderId.substring(0, 8)}',
      amount: amount,
    );
  }
}

