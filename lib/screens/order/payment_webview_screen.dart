import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 발주 결제창 — 토스페이먼츠 결제위젯(웹)을 앱 안 웹뷰로 띄운다.
///
/// 서버가 [donePath] 로 보내면 결제가 끝난 것이므로 웹뷰를 닫는다.
/// 성공 여부는 이 화면이 판단하지 않는다 — 호출한 쪽이 서버에 다시 확인한다.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.donePath,
    this.amount,
  });

  final String url;
  final String donePath;
  final int? amount;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigate,
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (e) {
          // 하위 리소스 오류는 무시하고 본문 오류만 표시
          if (e.isForMainFrame ?? false) {
            if (mounted) setState(() => _error = e.description);
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  NavigationDecision _onNavigate(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);

    // 결제 종료 — 웹뷰를 닫고 결과 확인은 호출한 쪽에 맡긴다
    if (uri != null && uri.path.contains(widget.donePath)) {
      Navigator.of(context).maybePop(uri.queryParameters);
      return NavigationDecision.prevent;
    }

    // 카드사·간편결제 앱 이동(intent:, market:, 은행 앱 등)은 외부 앱으로
    if (uri != null && uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme.isNotEmpty) {
      _openExternal(uri);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('결제 앱을 열지 못했습니다. 다른 결제수단을 선택해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      // 설치되지 않은 앱 등 — 무시(사용자가 다른 수단 선택)
    }
  }

  Future<void> _confirmClose() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('결제 취소'),
        content: const Text('결제를 취소할까요?\n결제하지 않으면 발주가 접수되지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('계속 결제')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('결제 취소'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: Text(widget.amount == null ? '발주 결제' : '발주 결제 · ${won(widget.amount!)}'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmClose),
        ),
        body: Stack(
          children: [
            if (_error == null) WebViewWidget(controller: _controller),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off_outlined, size: 40, color: AppColors.inkSoft),
                    const SizedBox(height: 12),
                    const Text('결제창을 열지 못했습니다.',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _loading = true;
                        });
                        _controller.loadRequest(Uri.parse(widget.url));
                      },
                      child: const Text('다시 시도'),
                    ),
                  ]),
                ),
              ),
            if (_loading && _error == null)
              const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}
