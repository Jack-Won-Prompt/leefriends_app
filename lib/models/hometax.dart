// 홈택스 매출/매입 세금계산서 수집 관련 모델.

class HometaxJob {
  HometaxJob({
    required this.id,
    required this.jobId,
    required this.tiType,
    required this.typeLabel,
    required this.jobState,
    required this.stateLabel,
    required this.collectCount,
    required this.done,
    this.startDate,
    this.endDate,
    this.errorReason,
    this.createdAt,
  });

  final int id;
  final String jobId;
  final String tiType; // SELL | BUY
  final String typeLabel;
  final int jobState; // 1 대기 2 진행 3 완료
  final String stateLabel;
  final int collectCount;
  final bool done;
  final String? startDate;
  final String? endDate;
  final String? errorReason;
  final String? createdAt;

  factory HometaxJob.fromJson(Map<String, dynamic> j) => HometaxJob(
        id: (j['id'] as num).toInt(),
        jobId: j['job_id']?.toString() ?? '',
        tiType: j['ti_type']?.toString() ?? 'SELL',
        typeLabel: j['type_label']?.toString() ?? '',
        jobState: (j['job_state'] as num?)?.toInt() ?? 1,
        stateLabel: j['state_label']?.toString() ?? '',
        collectCount: (j['collect_count'] as num?)?.toInt() ?? 0,
        done: j['done'] == true,
        startDate: j['start_date']?.toString(),
        endDate: j['end_date']?.toString(),
        errorReason: j['error_reason']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class HometaxInvoice {
  HometaxInvoice({
    required this.ntsConfirmNum,
    this.writeDate,
    this.taxType,
    this.invoicerCorpName,
    this.invoicerCorpNum,
    this.invoiceeCorpName,
    this.invoiceeCorpNum,
    this.supply = 0,
    this.tax = 0,
    this.total = 0,
  });

  final String ntsConfirmNum;
  final String? writeDate;
  final String? taxType;
  final String? invoicerCorpName;
  final String? invoicerCorpNum;
  final String? invoiceeCorpName;
  final String? invoiceeCorpNum;
  final int supply;
  final int tax;
  final int total;

  factory HometaxInvoice.fromJson(Map<String, dynamic> j) => HometaxInvoice(
        ntsConfirmNum: j['ntsconfirmNum']?.toString() ?? '',
        writeDate: j['writeDate']?.toString(),
        taxType: j['taxType']?.toString(),
        invoicerCorpName: j['invoicerCorpName']?.toString(),
        invoicerCorpNum: j['invoicerCorpNum']?.toString(),
        invoiceeCorpName: j['invoiceeCorpName']?.toString(),
        invoiceeCorpNum: j['invoiceeCorpNum']?.toString(),
        supply: (j['supplyCostTotal'] as num?)?.toInt() ?? 0,
        tax: (j['taxTotal'] as num?)?.toInt() ?? 0,
        total: (j['totalAmount'] as num?)?.toInt() ?? 0,
      );
}

class HometaxSummary {
  HometaxSummary({this.count = 0, this.supply = 0, this.tax = 0, this.amount = 0});
  final int count;
  final int supply;
  final int tax;
  final int amount;

  factory HometaxSummary.fromJson(Map<String, dynamic> j) => HometaxSummary(
        count: (j['count'] as num?)?.toInt() ?? 0,
        supply: (j['supply'] as num?)?.toInt() ?? 0,
        tax: (j['tax'] as num?)?.toInt() ?? 0,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
      );
}

class HometaxIndex {
  HometaxIndex({
    required this.type,
    this.certExpire,
    this.flatRateState,
    this.jobs = const [],
    this.selectedJobId,
    this.summary,
    this.invoices = const [],
    this.page = 1,
    this.pageCount = 1,
    this.error,
  });

  final String type;
  final String? certExpire;
  final String? flatRateState; // 정액제 상태 텍스트(있으면)
  final List<HometaxJob> jobs;
  final String? selectedJobId;
  final HometaxSummary? summary;
  final List<HometaxInvoice> invoices;
  final int page;
  final int pageCount;
  final String? error;

  factory HometaxIndex.fromJson(Map<String, dynamic> j) {
    final fr = j['flat_rate'];
    return HometaxIndex(
      type: j['type']?.toString() ?? 'SELL',
      certExpire: j['cert_expire']?.toString(),
      flatRateState: fr is Map ? (fr['state']?.toString()) : null,
      jobs: (j['jobs'] as List? ?? [])
          .map((e) => HometaxJob.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedJobId: j['selected_job_id']?.toString(),
      summary: j['summary'] is Map
          ? HometaxSummary.fromJson(j['summary'] as Map<String, dynamic>)
          : null,
      invoices: (j['invoices'] as List? ?? [])
          .map((e) => HometaxInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (j['page'] as num?)?.toInt() ?? 1,
      pageCount: (j['page_count'] as num?)?.toInt() ?? 1,
      error: j['error']?.toString(),
    );
  }
}

class HometaxJobState {
  HometaxJobState({
    required this.ok,
    this.state = 1,
    this.label = '',
    this.count = 0,
    this.done = false,
    this.errorReason,
    this.message,
  });
  final bool ok;
  final int state;
  final String label;
  final int count;
  final bool done;
  final String? errorReason;
  final String? message;

  factory HometaxJobState.fromJson(Map<String, dynamic> j) => HometaxJobState(
        ok: j['ok'] == true,
        state: (j['state'] as num?)?.toInt() ?? 1,
        label: j['label']?.toString() ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        done: j['done'] == true,
        errorReason: j['error_reason']?.toString(),
        message: j['message']?.toString(),
      );
}
