import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_colors.dart';

/// 송장/출고지시서 바코드·QR 스캔 화면. 인식되면 문자열을 Navigator.pop 으로 반환.
///
/// 카메라는 플러그인에 전적으로 맡긴다 — MobileScanner 에 controller 를 넘기지 않으면
/// 위젯이 컨트롤러 생성·시작·앱 생명주기(백그라운드 정지/복귀 재시작)·정리를 모두 처리한다.
/// (controller 를 직접 넘기면 attach 이후에 start 해야 하는 등 순서를 전부 떠안게 되고,
///  순서가 어긋나면 "카메라를 시작할 수 없습니다" 로 이어진다.)
///
/// 이 화면이 하는 일은 셋뿐이다:
///  1) 카메라 권한 확보  2) 실패 시 위젯을 통째로 새로 만들어 재시도  3) 번호 직접 입력 대체수단
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.title = '바코드 스캔'});
  final String title;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> with WidgetsBindingObserver {
  bool _handled = false;
  int _attempt = 0; // 값이 바뀌면 스캐너 위젯이 새로 생성된다(= 카메라 재시작)
  PermissionStatus? _perm; // null = 확인 중

  bool get _granted => _perm?.isGranted ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensurePermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 설정에서 권한을 허용하고 돌아온 경우 재확인. 카메라 정지/재개는 위젯이 알아서 한다.
    if (state == AppLifecycleState.resumed && !_granted) {
      _ensurePermission();
    }
  }

  // ── 권한 ──────────────────────────────────────────────────────────────

  /// 권한 확인 후 없으면 시스템 팝업 요청.
  Future<void> _ensurePermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() => _perm = status);
  }

  /// "카메라 권한 허용" 버튼 — 팝업 재요청(가능하면) 또는 설정 열기.
  Future<void> _requestOrSettings() async {
    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    final res = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _perm = res);
  }

  // ── 스캔 ──────────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(code.trim());
  }

  /// 카메라 재시작 — 스캐너 위젯을 폐기하고 새로 만든다.
  void _retry() => setState(() => _attempt++);

  /// 카메라 인식이 안 될 때 대비 — 코드 직접 입력.
  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('직접 입력'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: '번호 입력 (예: PO-20260813-004)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('확인')),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted) return;
    if (code != null && code.isNotEmpty) Navigator.of(context).pop(code);
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: '직접 입력',
            icon: const Icon(Icons.keyboard),
            onPressed: _manualEntry,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    // 권한 확인 중
    if (_perm == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    // 권한 없음 — 인앱 안내 + 버튼
    if (!_granted) {
      final permanentlyDenied = _perm!.isPermanentlyDenied;
      return _notice(
        title: '카메라 권한이 필요합니다',
        message: permanentlyDenied
            ? '권한이 거부되어 있습니다. 설정에서 카메라를 허용해 주세요.'
            : 'QR/바코드를 스캔하려면 카메라 권한을 허용해 주세요.',
        actionIcon: permanentlyDenied ? Icons.settings : Icons.camera_alt_outlined,
        actionLabel: permanentlyDenied ? '설정에서 권한 허용' : '카메라 권한 허용',
        onAction: _requestOrSettings,
      );
    }
    // 권한 있음 — 스캐너. 구성은 기본값 그대로(후면 카메라, 전 포맷, 기본 해상도).
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          key: ValueKey(_attempt),
          onDetect: _onDetect,
          placeholderBuilder: (context) =>
              const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          errorBuilder: (context, error) => _notice(
            title: '카메라를 시작할 수 없습니다.',
            message: '다른 앱이 카메라를 사용 중인지 확인하거나, 번호를 직접 입력해 주세요.',
            detail: '[${error.errorCode.name}] '
                '${error.errorDetails?.message ?? error.errorDetails?.details ?? '상세 없음'}',
            actionIcon: Icons.refresh,
            actionLabel: '다시 시도',
            onAction: _retry,
          ),
        ),
        // 스캔 가이드 박스
        IgnorePointer(
          child: Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 24,
          right: 24,
          child: Text(
            '바코드/QR을 사각형 안에 맞춰 주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 권한/오류 안내 공통 레이아웃 — 항상 "번호 직접 입력" 대체 수단을 함께 제공한다.
  Widget _notice({
    required String title,
    required String message,
    required IconData actionIcon,
    required String actionLabel,
    required VoidCallback onAction,
    String? detail,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 44),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
            if (detail != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onAction, icon: Icon(actionIcon), label: Text(actionLabel)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _manualEntry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              icon: const Icon(Icons.keyboard),
              label: const Text('번호 직접 입력'),
            ),
          ],
        ),
      ),
    );
  }
}
