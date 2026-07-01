import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/attendance.dart';
import 'api_config.dart';
import 'auth_controller.dart';
import 'order_repository.dart' show OrderException;

/// 근태(출퇴근·휴무·급여) API 클라이언트 — 아르바이트/정직원 공용. 토큰 인증 필요.
class AttendanceRepository {
  AttendanceRepository({required this.auth, http.Client? client})
      : _client = client ?? http.Client();

  final AuthController auth;
  final http.Client _client;

  // ---- 출퇴근 (아르바이트 본인) ----
  Future<AttendanceIndex> myAttendance() async =>
      AttendanceIndex.fromJson(await _send('GET', '/attendance'));

  Future<String> clockIn() async =>
      (await _send('POST', '/attendance/clock-in'))['message']?.toString() ?? '출근을 등록했습니다.';

  Future<String> clockOut() async =>
      (await _send('POST', '/attendance/clock-out'))['message']?.toString() ?? '퇴근을 등록했습니다.';

  Future<String> addRecord(
      {required String workDate, required String clockIn, String? clockOut}) async {
    final b = await _send('POST', '/attendance/record', {
      'work_date': workDate,
      'clock_in': clockIn,
      if (clockOut != null && clockOut.isNotEmpty) 'clock_out': clockOut,
    });
    return b['message']?.toString() ?? '출퇴근을 등록했습니다.';
  }

  Future<String> updateOwn(int id,
      {required String workDate, required String clockIn, String? clockOut}) async {
    final b = await _send('PUT', '/attendance/$id/own', {
      'work_date': workDate,
      'clock_in': clockIn,
      if (clockOut != null && clockOut.isNotEmpty) 'clock_out': clockOut,
    });
    return b['message']?.toString() ?? '수정했습니다.';
  }

  Future<String> deleteOwn(int id) async =>
      (await _send('DELETE', '/attendance/$id/own'))['message']?.toString() ?? '삭제했습니다.';

  // ---- 승인 (정직원) ----
  Future<ApprovalsData> approvals({String status = 'all', int? userId}) async {
    final q = <String>['status=$status'];
    if (userId != null) q.add('user=$userId');
    return ApprovalsData.fromJson(await _send('GET', '/attendance/approvals?${q.join('&')}'));
  }

  Future<String> approve(int id) async =>
      (await _send('PATCH', '/attendance/$id/approve'))['message']?.toString() ?? '승인했습니다.';

  Future<String> reject(int id) async =>
      (await _send('PATCH', '/attendance/$id/reject'))['message']?.toString() ?? '반려했습니다.';

  Future<String> bulkApprove(List<int> ids) async {
    final b = await _send('POST', '/attendance/bulk-approve', {'attendance_ids': ids});
    return b['message']?.toString() ?? '일괄 승인했습니다.';
  }

  Future<String> manageStore(int userId,
      {required String workDate, required String clockIn, String? clockOut}) async {
    final b = await _send('POST', '/attendance/manage/$userId', {
      'work_date': workDate,
      'clock_in': clockIn,
      if (clockOut != null && clockOut.isNotEmpty) 'clock_out': clockOut,
    });
    return b['message']?.toString() ?? '등록했습니다.';
  }

  // ---- 휴무 ----
  Future<({bool isPartTime, List<LeaveRecord> leaves})> myLeaves() async {
    final b = await _send('GET', '/leaves');
    return (
      isPartTime: b['is_part_time'] == true,
      leaves: (b['leaves'] as List? ?? [])
          .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<String> requestLeave(String leaveDate, String? reason) async {
    final b = await _send('POST', '/leaves', {
      'leave_date': leaveDate,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return b['message']?.toString() ?? '휴무를 신청했습니다.';
  }

  Future<String> cancelLeave(int id) async =>
      (await _send('DELETE', '/leaves/$id'))['message']?.toString() ?? '취소했습니다.';

  Future<String> approveLeave(int id) async =>
      (await _send('PATCH', '/leaves/$id/approve'))['message']?.toString() ?? '승인했습니다.';

  Future<String> rejectLeave(int id) async =>
      (await _send('PATCH', '/leaves/$id/reject'))['message']?.toString() ?? '반려했습니다.';

  // ---- 급여 (정직원) ----
  Future<WageIndex> wages({String? from, String? to}) async {
    final q = <String>[];
    if (from != null) q.add('from=$from');
    if (to != null) q.add('to=$to');
    final qs = q.isEmpty ? '' : '?${q.join('&')}';
    return WageIndex.fromJson(await _send('GET', '/wages$qs'));
  }

  Future<String> payWage(
      {required int userId,
      required String from,
      required String to,
      required double hours,
      required int amount}) async {
    final b = await _send('POST', '/wages/pay', {
      'user_id': userId,
      'from': from,
      'to': to,
      'hours': hours,
      'amount': amount,
    });
    return b['message']?.toString() ?? '입금 처리했습니다.';
  }

  Future<String> unpayWage(int settlementId) async =>
      (await _send('DELETE', '/wages/$settlementId'))['message']?.toString() ?? '취소했습니다.';

  // ---- helper ----
  Future<Map<String, dynamic>> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final req = http.Request(method, uri)
      ..headers.addAll({...auth.authHeaders, 'Content-Type': 'application/json'});
    if (body != null) req.body = jsonEncode(body);
    final streamed = await _client.send(req).timeout(ApiConfig.timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _error(Map<String, dynamic> body, int status) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    if (body['message'] is String) return body['message'] as String;
    if (status == 401) return '로그인이 필요합니다.';
    return '요청을 처리하지 못했습니다 ($status).';
  }
}
