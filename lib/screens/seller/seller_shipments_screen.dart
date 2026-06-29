import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/paged.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import 'barcode_scan_screen.dart';
import 'create_shipment_screen.dart';
import 'seller_widgets.dart';

class SellerShipmentsScreen extends StatefulWidget {
  const SellerShipmentsScreen(
      {super.key, required this.repository, this.onChanged, this.initialStatus = 'all'});
  final SellerRepository repository;
  final VoidCallback? onChanged;
  final String initialStatus;

  @override
  State<SellerShipmentsScreen> createState() => _SellerShipmentsScreenState();
}

class _SellerShipmentsScreenState extends State<SellerShipmentsScreen> {
  late String _status = widget.initialStatus;
  List<StatusOption> _statuses = const [];
  int _reloadToken = 0;

  void _select(String s) => setState(() => _status = s);
  void _reload() => setState(() => _reloadToken++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('출고')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CreateShipmentScreen(repository: widget.repository),
          ));
          _reload();
          widget.onChanged?.call();
        },
        icon: const Icon(Icons.add),
        label: const Text('출고 생성', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          StatusFilterBar(statuses: _statuses, selected: _status, onSelect: _select),
          Expanded(
            child: PagedListView<SellerShipment>(
              key: ValueKey('$_status-$_reloadToken'),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              emptyText: '출고 내역이 없습니다',
              fetch: (page) async {
                final r = await widget.repository.shipments(status: _status, page: page);
                if (page == 1 && _statuses.isEmpty && r.statuses.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _statuses = r.statuses);
                  });
                }
                return Paged(items: r.shipments, hasMore: r.hasMore);
              },
              itemBuilder: (context, s) => _Tile(
                s: s,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ShipmentConfirmScreen(
                        repository: widget.repository, id: s.id, onChanged: widget.onChanged),
                  ));
                  _reload();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.s, required this.onTap});
  final SellerShipment s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: s.status == 'created' ? AppColors.mango300 : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(s.shipmentNo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              FulfillStatusChip(status: s.status, label: s.statusLabel),
            ]),
            const SizedBox(height: 8),
            Text('${s.storeName ?? ''} · ${s.itemCount}품목 ${s.totalQty}개'
                '${s.carrier != null ? ' · ${s.carrier} ${s.trackingNo ?? ''}' : ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

/// 출고 상세 + 송장 입력/확정.
class ShipmentConfirmScreen extends StatefulWidget {
  const ShipmentConfirmScreen(
      {super.key, required this.repository, required this.id, this.onChanged});
  final SellerRepository repository;
  final int id;
  final VoidCallback? onChanged;

  @override
  State<ShipmentConfirmScreen> createState() => _ShipmentConfirmScreenState();
}

class _ShipmentConfirmScreenState extends State<ShipmentConfirmScreen> {
  late Future<SellerShipment> _future;
  final _tracking = TextEditingController();
  List<CarrierOption> _carriers = const [];
  CarrierOption? _selectedCarrier;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.shipmentDetail(widget.id);
    _loadCarriers();
  }

  Future<void> _loadCarriers() async {
    try {
      final list = await widget.repository.couriers();
      if (mounted) setState(() => _carriers = list);
    } catch (_) {
      // 목록 로드 실패 시 확정 단계에서 안내
    }
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final carrier = _selectedCarrier;
    if (carrier == null) {
      _toast('택배사를 선택해 주세요.');
      return;
    }
    if (!carrier.isDirect && _tracking.text.trim().isEmpty) {
      _toast('송장번호를 입력해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final s = await widget.repository.confirmShipment(
          widget.id, carrier.name, carrier.isDirect ? '' : _tracking.text.trim());
      widget.onChanged?.call();
      setState(() { _future = Future.value(s); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('출고 확정 완료. 매장에 배송시작 알림을 보냈습니다.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('출고 상세')),
      body: FutureBuilder<SellerShipment>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          final s = snap.data!;
          final created = s.status == 'created';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
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
                      Text(s.shipmentNo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      FulfillStatusChip(status: s.status, label: s.statusLabel),
                    ]),
                    const SizedBox(height: 8),
                    Text('${s.storeName ?? ''} · ${s.itemCount}품목 ${s.totalQty}개',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                    if (s.carrier != null) ...[
                      const SizedBox(height: 6),
                      Text('${s.carrier} · ${s.trackingNo ?? ''}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('출고 품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final it in s.items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(it.productName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                    Text('${it.qty}${it.unit}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ]),
                ),
              if (created) ...[
                const SizedBox(height: 16),
                const Text('택배사 선택 후 출고확정',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _carrierPicker(),
                if (_selectedCarrier != null && !_selectedCarrier!.isDirect) ...[
                  const SizedBox(height: 10),
                  _field(_tracking, '송장번호',
                      suffix: IconButton(
                        tooltip: '바코드 스캔',
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.accent),
                        onPressed: _scanTracking,
                      )),
                ],
                if (_selectedCarrier?.isDirect == true) ...[
                  const SizedBox(height: 8),
                  const Text('직접 배송은 송장번호가 필요하지 않습니다.',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<SellerShipment>(
        future: _future,
        builder: (context, snap) {
          if (snap.data?.status != 'created') return const SizedBox.shrink();
          return Container(
            color: AppColors.cream,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirm,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              icon: _busy
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.local_shipping_outlined),
              label: const Text('출고 확정 (배송시작)'),
            ),
          );
        },
      ),
    );
  }

  Widget _carrierPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CarrierOption>(
          value: _selectedCarrier,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.inkSoft,
          style: const TextStyle(
              color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
          hint: Text(_carriers.isEmpty ? '택배사 불러오는 중…' : '택배사 선택',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 14)),
          items: _carriers
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.isDirect ? '${c.name} (송장 불필요)' : c.name,
                        style: const TextStyle(
                            color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
          onChanged: _carriers.isEmpty
              ? null
              : (c) => setState(() => _selectedCarrier = c),
        ),
      ),
    );
  }

  void _toast(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.mango800 : const Color(0xFFB02A2A),
    ));
  }

  Future<void> _scanTracking() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => const BarcodeScanScreen(title: '송장 바코드 스캔'),
    ));
    if (code != null && code.isNotEmpty) {
      setState(() => _tracking.text = code);
    }
  }

  Widget _field(TextEditingController c, String hint, {Widget? suffix}) => TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
