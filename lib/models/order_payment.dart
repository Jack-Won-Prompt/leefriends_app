// 매장 발주 결제(토스페이먼츠) 모델 — 결제 매장만 사용.

/// 결제가 필요하다는 서버 응답. 결제가 끝나야 발주가 접수된다.
class PaymentCheckout {
  final String checkoutId; // 서버 결제 식별자 (결과 확인에 사용)
  final int amount;
  final String checkoutUrl; // 서명된 결제창 주소 (앱 웹뷰)
  final String donePath; // 웹뷰가 이 경로로 이동하면 결제 종료
  final bool testMode;

  const PaymentCheckout({
    required this.checkoutId,
    required this.amount,
    required this.checkoutUrl,
    required this.donePath,
    this.testMode = false,
  });

  static PaymentCheckout? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final url = j['checkout_url'] as String?;
    final id = j['checkout_id'] as String?;
    if (url == null || url.isEmpty || id == null || id.isEmpty) return null;
    return PaymentCheckout(
      checkoutId: id,
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      checkoutUrl: url,
      donePath: j['done_path'] as String? ?? '/pay/app/done',
      testMode: j['test_mode'] as bool? ?? false,
    );
  }
}

/// 결제 결과 — 웹뷰 리다이렉트를 믿지 않고 서버에 다시 확인한 값.
class CheckoutStatus {
  /// paid · waiting_deposit · awaiting · failed · pending · unknown
  final String status;
  final int? orderId;
  final String? orderNo;
  final String? message;

  const CheckoutStatus({required this.status, this.orderId, this.orderNo, this.message});

  bool get isPaid => status == 'paid';

  /// 발주가 접수된 상태 (가상계좌 입금 대기 포함)
  bool get isAccepted => status == 'paid' || status == 'waiting_deposit' || status == 'awaiting';

  factory CheckoutStatus.fromJson(Map<String, dynamic> j) => CheckoutStatus(
        status: j['status'] as String? ?? 'unknown',
        orderId: (j['order_id'] as num?)?.toInt(),
        orderNo: j['order_no'] as String?,
        message: j['message'] as String?,
      );
}
