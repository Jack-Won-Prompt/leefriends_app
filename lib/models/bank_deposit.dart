// 본사 계좌 입금확인(계좌 거래내역 수집 + 주문 대사) 모델.

class BankAccount {
  BankAccount({required this.key, required this.bankCode, required this.accountNumber, this.accountName});
  final String key; // bankCode|accountNumber
  final String bankCode;
  final String accountNumber;
  final String? accountName;

  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
        key: j['key']?.toString() ?? '',
        bankCode: j['bank_code']?.toString() ?? '',
        accountNumber: j['account_number']?.toString() ?? '',
        accountName: j['account_name']?.toString(),
      );

  String get label => '${accountName ?? ''} $accountNumber'.trim();
}

class BankJob {
  BankJob({required this.id, required this.jobId, required this.jobState, required this.stateLabel, required this.done, this.errorReason});
  final int id;
  final String jobId;
  final int jobState;
  final String stateLabel;
  final bool done;
  final String? errorReason;

  factory BankJob.fromJson(Map<String, dynamic> j) => BankJob(
        id: (j['id'] as num).toInt(),
        jobId: j['job_id']?.toString() ?? '',
        jobState: (j['job_state'] as num?)?.toInt() ?? 1,
        stateLabel: j['state_label']?.toString() ?? '',
        done: j['done'] == true,
        errorReason: j['error_reason']?.toString(),
      );
}

class BankOrderRef {
  BankOrderRef({required this.id, required this.orderNo, this.storeName, this.total, this.createdAt});
  final int id;
  final String orderNo;
  final String? storeName;
  final int? total;
  final String? createdAt;

  factory BankOrderRef.fromJson(Map<String, dynamic> j) => BankOrderRef(
        id: (j['id'] as num).toInt(),
        orderNo: j['order_no']?.toString() ?? '',
        storeName: j['store_name']?.toString(),
        total: (j['total'] as num?)?.toInt(),
        createdAt: j['created_at']?.toString(),
      );
}

class BankStoreRef {
  BankStoreRef({required this.id, required this.name});
  final int id;
  final String name;
  factory BankStoreRef.fromJson(Map<String, dynamic> j) =>
      BankStoreRef(id: (j['id'] as num).toInt(), name: j['name']?.toString() ?? '');
}

class BankDepositItem {
  BankDepositItem({
    required this.id,
    required this.accIn,
    this.tradeDate,
    this.depositor,
    this.remark,
    this.matched = false,
    this.matchedOrder,
    this.resolvedStore,
    this.candidates = const [],
  });

  final int id;
  final int accIn;
  final String? tradeDate;
  final String? depositor;
  final String? remark;
  final bool matched;
  final BankOrderRef? matchedOrder;
  final BankStoreRef? resolvedStore;
  final List<BankOrderRef> candidates;

  factory BankDepositItem.fromJson(Map<String, dynamic> j) => BankDepositItem(
        id: (j['id'] as num).toInt(),
        accIn: (j['acc_in'] as num?)?.toInt() ?? 0,
        tradeDate: j['trade_date']?.toString(),
        depositor: j['depositor']?.toString(),
        remark: j['remark']?.toString(),
        matched: j['matched'] == true,
        matchedOrder: j['matched_order'] is Map
            ? BankOrderRef.fromJson(j['matched_order'] as Map<String, dynamic>)
            : null,
        resolvedStore: j['resolved_store'] is Map
            ? BankStoreRef.fromJson(j['resolved_store'] as Map<String, dynamic>)
            : null,
        candidates: (j['candidates'] as List? ?? [])
            .map((e) => BankOrderRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BankIndex {
  BankIndex({
    this.accountsError,
    this.accounts = const [],
    this.selectedAcc,
    this.jobs = const [],
    this.selectedJobId,
    this.deposits = const [],
    this.stores = const [],
    this.total = 0,
    this.matchedCount = 0,
    this.unmatchedCount = 0,
    this.count = 0,
    this.defStart,
    this.defEnd,
  });

  final String? accountsError;
  final List<BankAccount> accounts;
  final String? selectedAcc;
  final List<BankJob> jobs;
  final String? selectedJobId;
  final List<BankDepositItem> deposits;
  final List<BankStoreRef> stores;
  final int total;
  final int matchedCount;
  final int unmatchedCount;
  final int count;
  final String? defStart;
  final String? defEnd;

  factory BankIndex.fromJson(Map<String, dynamic> j) {
    final sum = (j['summary'] as Map<String, dynamic>?) ?? {};
    return BankIndex(
      accountsError: j['accounts_error']?.toString(),
      accounts: (j['accounts'] as List? ?? [])
          .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedAcc: j['selected_acc']?.toString(),
      jobs: (j['jobs'] as List? ?? [])
          .map((e) => BankJob.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedJobId: j['selected_job_id']?.toString(),
      deposits: (j['deposits'] as List? ?? [])
          .map((e) => BankDepositItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      stores: (j['stores'] as List? ?? [])
          .map((e) => BankStoreRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (sum['total'] as num?)?.toInt() ?? 0,
      matchedCount: (sum['matched'] as num?)?.toInt() ?? 0,
      unmatchedCount: (sum['unmatched'] as num?)?.toInt() ?? 0,
      count: (sum['count'] as num?)?.toInt() ?? 0,
      defStart: j['def_start']?.toString(),
      defEnd: j['def_end']?.toString(),
    );
  }
}
