// 근태관리(출퇴근·휴무·급여) + 직원 관리 모델.

class StaffMember {
  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.employmentType = 'regular',
    this.employmentLabel = '정직원',
    this.hourlyWage = 0,
    this.isAdmin = false,
    this.isSelf = false,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String employmentType; // regular | part_time
  final String employmentLabel;
  final int hourlyWage;
  final bool isAdmin;
  final bool isSelf;

  bool get isPartTime => employmentType == 'part_time';

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        phone: j['phone']?.toString(),
        employmentType: j['employment_type']?.toString() ?? 'regular',
        employmentLabel: j['employment_label']?.toString() ?? '정직원',
        hourlyWage: (j['hourly_wage'] as num?)?.toInt() ?? 0,
        isAdmin: j['is_admin'] == true,
        isSelf: j['is_self'] == true,
      );
}

class StaffRef {
  StaffRef({required this.id, required this.name});
  final int id;
  final String name;
  factory StaffRef.fromJson(Map<String, dynamic> j) =>
      StaffRef(id: (j['id'] as num).toInt(), name: j['name']?.toString() ?? '');
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    this.workDate,
    this.clockIn,
    this.clockOut,
    this.hours = 0,
    this.status = 'pending',
    this.statusLabel = '',
    this.isOpen = false,
    this.note,
    this.user,
  });

  final int id;
  final String? workDate;
  final String? clockIn; // HH:mm
  final String? clockOut;
  final double hours;
  final String status; // pending | approved | rejected
  final String statusLabel;
  final bool isOpen;
  final String? note;
  final StaffRef? user;

  bool get isApproved => status == 'approved';

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: (j['id'] as num).toInt(),
        workDate: j['work_date']?.toString(),
        clockIn: j['clock_in']?.toString(),
        clockOut: j['clock_out']?.toString(),
        hours: (j['hours'] as num?)?.toDouble() ?? 0,
        status: j['status']?.toString() ?? 'pending',
        statusLabel: j['status_label']?.toString() ?? '',
        isOpen: j['is_open'] == true,
        note: j['note']?.toString(),
        user: j['user'] is Map ? StaffRef.fromJson(j['user'] as Map<String, dynamic>) : null,
      );
}

class AttendanceIndex {
  AttendanceIndex({this.isPartTime = false, this.open, this.records = const []});
  final bool isPartTime;
  final AttendanceRecord? open;
  final List<AttendanceRecord> records;

  factory AttendanceIndex.fromJson(Map<String, dynamic> j) => AttendanceIndex(
        isPartTime: j['is_part_time'] == true,
        open: j['open'] is Map
            ? AttendanceRecord.fromJson(j['open'] as Map<String, dynamic>)
            : null,
        records: (j['records'] as List? ?? [])
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LeaveRecord {
  LeaveRecord({
    required this.id,
    this.leaveDate,
    this.reason,
    this.status = 'pending',
    this.statusLabel = '',
    this.user,
  });

  final int id;
  final String? leaveDate;
  final String? reason;
  final String status;
  final String statusLabel;
  final StaffRef? user;

  bool get isApproved => status == 'approved';

  factory LeaveRecord.fromJson(Map<String, dynamic> j) => LeaveRecord(
        id: (j['id'] as num).toInt(),
        leaveDate: j['leave_date']?.toString(),
        reason: j['reason']?.toString(),
        status: j['status']?.toString() ?? 'pending',
        statusLabel: j['status_label']?.toString() ?? '',
        user: j['user'] is Map ? StaffRef.fromJson(j['user'] as Map<String, dynamic>) : null,
      );
}

class ApprovalsData {
  ApprovalsData({this.parttimers = const [], this.attendances = const [], this.leaves = const []});
  final List<StaffRef> parttimers;
  final List<AttendanceRecord> attendances;
  final List<LeaveRecord> leaves;

  factory ApprovalsData.fromJson(Map<String, dynamic> j) => ApprovalsData(
        parttimers: (j['parttimers'] as List? ?? [])
            .map((e) => StaffRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        attendances: (j['attendances'] as List? ?? [])
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        leaves: (j['leaves'] as List? ?? [])
            .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WageRow {
  WageRow({
    required this.userId,
    required this.name,
    this.hourlyWage = 0,
    this.days = 0,
    this.hours = 0,
    this.amount = 0,
    this.paid = false,
    this.settlementId,
    this.paidAt,
  });

  final int userId;
  final String name;
  final int hourlyWage;
  final int days;
  final double hours;
  final int amount;
  final bool paid;
  final int? settlementId;
  final String? paidAt;

  factory WageRow.fromJson(Map<String, dynamic> j) => WageRow(
        userId: (j['user_id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        hourlyWage: (j['hourly_wage'] as num?)?.toInt() ?? 0,
        days: (j['days'] as num?)?.toInt() ?? 0,
        hours: (j['hours'] as num?)?.toDouble() ?? 0,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        paid: j['paid'] == true,
        settlementId: (j['settlement_id'] as num?)?.toInt(),
        paidAt: j['paid_at']?.toString(),
      );
}

class WageIndex {
  WageIndex({this.from, this.to, this.grandAmount = 0, this.rows = const []});
  final String? from;
  final String? to;
  final int grandAmount;
  final List<WageRow> rows;

  factory WageIndex.fromJson(Map<String, dynamic> j) => WageIndex(
        from: j['from']?.toString(),
        to: j['to']?.toString(),
        grandAmount: (j['grand_amount'] as num?)?.toInt() ?? 0,
        rows: (j['rows'] as List? ?? [])
            .map((e) => WageRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
