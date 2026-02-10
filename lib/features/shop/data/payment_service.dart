class PaymentService {
  Future<String> startOnlinePayment({
    required double amount,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'PAY-$ts';
  }
}
