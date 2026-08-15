import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_colors.dart';

/// 송장 바코드/QR 스캔 화면. 인식되면 문자열을 Navigator.pop 으로 반환.
/// 카메라 권한을 인앱 팝업으로 직접 요청하고, 영구거부 시 설정으로 안내한다.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.title = '바코드 스캔'});
  final String title;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    // 택배 송장에 흔한 1D 바코드 + QR 우선
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.codabar,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.qrCode,
    ],
  );
  bool _handled = false;
  PermissionStatus? _perm; // null = 확인 중

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensurePermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 설정에서 권한 허용 후 복귀 시 재확인
    if (state == AppLifecycleState.resumed && _perm != null && !_perm!.isGranted) {
      _refreshPermission();
    }
  }

  /// 최초 진입 — 권한 확인 후 없으면 팝업 요청.
  Future<void> _ensurePermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      status = await Permission.camera.request(); // 시스템 권한 팝업
    }
    if (mounted) setState(() => _perm = status);
  }

  /// "카메라 권한 허용" 버튼 — 팝업 재요청(가능하면) 또는 설정 열기.
  Future<void> _requestOrSettings() async {
    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    final res = await Permission.camera.request();
    if (mounted) setState(() => _perm = res);
  }

  Future<void> _refreshPermission() async {
    final status = await Permission.camera.status;
    if (mounted) setState(() => _perm = status);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(code.trim());
  }

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
          if (_perm?.isGranted ?? false) ...[
            IconButton(
              tooltip: '플래시',
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller.toggleTorch(),
            ),
            IconButton(
              tooltip: '카메라 전환',
              icon: const Icon(Icons.cameraswitch),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
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
    if (!_perm!.isGranted) {
      final permanentlyDenied = _perm!.isPermanentlyDenied;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 44),
              const SizedBox(height: 14),
              const Text('카메라 권한이 필요합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                  permanentlyDenied
                      ? '권한이 거부되어 있습니다. 설정에서 카메라를 허용해 주세요.'
                      : 'QR/바코드를 스캔하려면 카메라 권한을 허용해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _requestOrSettings,
                icon: Icon(permanentlyDenied ? Icons.settings : Icons.camera_alt_outlined),
                label: Text(permanentlyDenied ? '설정에서 권한 허용' : '카메라 권한 허용'),
              ),
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
    // 권한 있음 — 스캐너
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 44),
                  const SizedBox(height: 14),
                  const Text('카메라를 시작할 수 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('다른 앱이 카메라를 사용 중인지 확인하거나, 번호를 직접 입력해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 10),
                  // 원인 진단용 상세 (오류코드/메시지)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      '[${error.errorCode.name}] ${error.errorDetails?.message ?? error.errorDetails?.details ?? '상세 없음'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _controller.start(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _manualEntry,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('직접 입력'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
}
