import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';
import 'barcode_scan_screen.dart';

/// 배송업무 — 출고지시서 QR(발주번호) 스캔 → 현장 사진 → 매장 담당자 서명 → 배송완료.
/// 배송완료 시 서버가 발주 상태를 배송완료(completed)로 바꾸고,
/// 해당 발주의 거래명세서 이메일 + 세금계산서를 자동 발행한다. (본사 전용)
class DeliveryWorkScreen extends StatefulWidget {
  const DeliveryWorkScreen({super.key, required this.repository, this.embedded = false});
  final SellerRepository repository;
  final bool embedded;

  @override
  State<DeliveryWorkScreen> createState() => _DeliveryWorkScreenState();
}

class _DeliveryWorkScreenState extends State<DeliveryWorkScreen> {
  SellerOrder? _order;
  final List<XFile> _photos = [];
  late final SignatureController _sig;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sig = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.ink,
      exportBackgroundColor: Colors.white,
    );
    _sig.addListener(() => setState(() {})); // 서명 상태에 따라 완료 버튼 활성화 갱신
  }

  @override
  void dispose() {
    _sig.dispose();
    super.dispose();
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m.replaceFirst('OrderException: ', '')),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => const BarcodeScanScreen(title: '출고지시서 QR 스캔'),
    ));
    if (code == null || code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final o = await widget.repository.lookupDeliveryOrder(code.trim());
      setState(() {
        _order = o;
        _photos.clear();
        _sig.clear();
      });
      if (o.status == 'completed') {
        _snack('발주 ${o.orderNo} 는 이미 배송완료된 발주입니다.', error: true);
      } else if (o.status == 'canceled') {
        _snack('발주 ${o.orderNo} 는 취소된 발주입니다.', error: true);
      }
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('카메라로 촬영'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('갤러리에서 선택'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ]),
      ),
    );
    if (choice == null) return;
    final x = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (x != null) setState(() => _photos.add(x));
  }

  bool get _canComplete =>
      _order != null &&
      _order!.status != 'completed' &&
      _order!.status != 'canceled' &&
      _photos.isNotEmpty &&
      _sig.isNotEmpty &&
      !_busy;

  Future<void> _complete() async {
    final s = _order;
    if (s == null) return;
    if (_photos.isEmpty) {
      _snack('현장 사진을 1장 이상 촬영해 주세요.', error: true);
      return;
    }
    if (_sig.isEmpty) {
      _snack('매장 담당자 서명을 받아 주세요.', error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('배송 완료'),
        content: Text(
            '발주 «${s.orderNo}» 를 배송완료로 처리합니다.\n'
            '매장(${s.storeName ?? ''})에 거래명세서가 전송되고 세금계산서가 자동 발행됩니다.'
            '${s.hasPendingPrice ? '\n\n⚠️ 싯가 미확정 품목이 있어 세금계산서는 보류됩니다.' : ''}\n진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E8E4E)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('배송 완료')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      // 서명 PNG 를 임시 파일로 저장
      final bytes = await _sig.toPngBytes();
      if (bytes == null) throw Exception('서명 이미지를 생성하지 못했습니다.');
      final sigFile = File(
          '${Directory.systemTemp.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png');
      await sigFile.writeAsBytes(bytes);

      final msg = await widget.repository.completeOrderDelivery(
        orderId: s.id,
        photoPaths: _photos.map((x) => x.path).toList(),
        signaturePath: sigFile.path,
      );
      if (!mounted) return;
      // 완료 → 초기화
      setState(() {
        _order = null;
        _photos.clear();
        _sig.clear();
      });
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('✅ 배송 완료'),
          content: Text(msg),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
          ],
        ),
      );
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _body();
    if (widget.embedded) return Container(color: AppColors.cream, child: body);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('배송업무')),
      body: body,
    );
  }

  Widget _body() {
    final s = _order;
    final done = s != null && (s.status == 'completed' || s.status == 'canceled');
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.of(context).padding.bottom),
      children: [
        // 스캔 버튼
        FilledButton.icon(
          onPressed: _busy ? null : _scan,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(s == null ? '출고지시서 QR 스캔' : '다른 발주 스캔'),
        ),
        const SizedBox(height: 16),
        if (s == null)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text('출고지시서의 QR을 스캔하면\n배송 처리를 시작합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft, height: 1.5)),
            ),
          )
        else ...[
          _orderCard(s),
          if (!done) ...[
            const SizedBox(height: 20),
            _photosSection(),
            const SizedBox(height: 20),
            _signatureSection(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _canComplete ? _complete : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: const Color(0xFF1E8E4E),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('배송 완료', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            if (!_canComplete && !_busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('사진 1장 이상 + 서명을 완료하면 배송완료가 활성화됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ),
          ],
        ],
      ],
    );
  }

  Widget _orderCard(SellerOrder s) {
    final completed = s.status == 'completed';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(s.orderNo,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: completed ? const Color(0xFFE7F6EC) : AppColors.mango100,
                  borderRadius: BorderRadius.circular(100)),
              child: Text(s.statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: completed ? const Color(0xFF1E8E4E) : AppColors.mango800)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('${s.storeName ?? ''} · ${s.itemCount}품목',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          if (s.hasPendingPrice)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('⚠️ 싯가 미확정 품목 포함 — 세금계산서는 보류됩니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC2660C), fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _photosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('현장 사진', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text('${_photos.length}장', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          const Spacer(),
          TextButton.icon(
            onPressed: _busy ? null : _addPhoto,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('사진 추가'),
          ),
        ]),
        const SizedBox(height: 4),
        SizedBox(
          height: 96,
          child: _photos.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Text('배송 현장 사진을 1장 이상 촬영해 주세요',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_photos[i].path),
                            width: 96, height: 96, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _signatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('매장 담당자 서명',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton.icon(
            onPressed: _busy || _sig.isEmpty ? null : () => _sig.clear(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시'),
          ),
        ]),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Signature(
            controller: _sig,
            height: 180,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text('위 칸에 매장 담당자의 서명을 받아 주세요.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      ],
    );
  }
}
