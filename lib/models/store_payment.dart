// 매장별 입금현황 모델.

class StorePaymentTotals {
  StorePaymentTotals({this.total = 0, this.paid = 0, this.unpaid = 0, this.unpaidCnt = 0});
  final int total;
  final int paid;
  final int unpaid;
  final int unpaidCnt;

  factory StorePaymentTotals.fromJson(Map<String, dynamic> j) => StorePaymentTotals(
        total: (j['total'] as num?)?.toInt() ?? 0,
        paid: (j['paid'] as num?)?.toInt() ?? 0,
        unpaid: (j['unpaid'] as num?)?.toInt() ?? 0,
        unpaidCnt: (j['unpaid_cnt'] as num?)?.toInt() ?? 0,
      );
}

class StorePaymentRow {
  StorePaymentRow({
    required this.id,
    required this.name,
    this.region,
    this.cnt = 0,
    this.total = 0,
    this.paid = 0,
    this.unpaid = 0,
    this.unpaidCnt = 0,
    this.lastPaidAt,
  });

  final int id;
  final String name;
  final String? region;
  final int cnt;
  final int total;
  final int paid;
  final int unpaid;
  final int unpaidCnt;
  final String? lastPaidAt;

  factory StorePaymentRow.fromJson(Map<String, dynamic> j) => StorePaymentRow(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        region: j['region']?.toString(),
        cnt: (j['cnt'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        paid: (j['paid'] as num?)?.toInt() ?? 0,
        unpaid: (j['unpaid'] as num?)?.toInt() ?? 0,
        unpaidCnt: (j['unpaid_cnt'] as num?)?.toInt() ?? 0,
        lastPaidAt: j['last_paid_at']?.toString(),
      );
}

class StorePaymentIndex {
  StorePaymentIndex({
    this.period = 'all',
    this.year = 0,
    this.month = 0,
    required this.totals,
    this.stores = const [],
  });

  final String period;
  final int year;
  final int month;
  final StorePaymentTotals totals;
  final List<StorePaymentRow> stores;

  factory StorePaymentIndex.fromJson(Map<String, dynamic> j) => StorePaymentIndex(
        period: j['period']?.toString() ?? 'all',
        year: (j['year'] as num?)?.toInt() ?? 0,
        month: (j['month'] as num?)?.toInt() ?? 0,
        totals: StorePaymentTotals.fromJson((j['totals'] as Map<String, dynamic>?) ?? {}),
        stores: (j['stores'] as List? ?? [])
            .map((e) => StorePaymentRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StorePaymentOrder {
  StorePaymentOrder({
    required this.id,
    required this.orderNo,
    this.statusLabel,
    this.itemCount = 0,
    this.total = 0,
    this.paid = false,
    this.paidAt,
    this.createdAt,
  });

  final int id;
  final String orderNo;
  final String? statusLabel;
  final int itemCount;
  final int total;
  final bool paid;
  final String? paidAt;
  final String? createdAt;

  factory StorePaymentOrder.fromJson(Map<String, dynamic> j) => StorePaymentOrder(
        id: (j['id'] as num).toInt(),
        orderNo: j['order_no']?.toString() ?? '',
        statusLabel: j['status_label']?.toString(),
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        paid: j['paid'] == true,
        paidAt: j['paid_at']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class StorePaymentDetail {
  StorePaymentDetail({required this.storeName, this.orders = const []});
  final String storeName;
  final List<StorePaymentOrder> orders;

  factory StorePaymentDetail.fromJson(Map<String, dynamic> j) => StorePaymentDetail(
        storeName: (j['store'] as Map<String, dynamic>?)?['name']?.toString() ?? '매장',
        orders: (j['orders'] as List? ?? [])
            .map((e) => StorePaymentOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
