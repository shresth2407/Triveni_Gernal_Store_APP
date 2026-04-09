// import 'package:upi_india/upi_india.dart';
//
// abstract class PaymentService {
//   Future<UpiResponse> initiateUpiPayment({
//     required String amount,
//     required String orderId,
//   });
// }
//
// class UpiPaymentService implements PaymentService {
//   final String receiverUpiId;
//   final String receiverName;
//   final UpiApp? defaultApp;
//   final UpiIndia _upiIndia;
//
//   UpiPaymentService({
//     this.receiverUpiId = 'merchant@upi',
//     this.receiverName = 'Grocery Store',
//     this.defaultApp,
//     UpiIndia? upiIndia,
//   }) : _upiIndia = upiIndia ?? UpiIndia();
//
//   @override
//   Future<UpiResponse> initiateUpiPayment({
//     required String amount,
//     required String orderId,
//   }) {
//     return _upiIndia.startTransaction(
//       app: defaultApp ?? UpiApp.googlePay,
//       receiverUpiId: receiverUpiId,
//       receiverName: receiverName,
//       transactionRefId: orderId,
//       transactionNote: 'Grocery order payment',
//       amount: double.parse(amount),
//     );
//   }
// }
