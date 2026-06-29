import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/chat_repository.dart';
import '../../models/chat.dart';
import '../../theme/app_colors.dart';
import 'chat_thread_screen.dart';

/// 채팅 진입점.
///  - 매장/공급처: 본사와의 단일 대화방 목록(1행)
///  - 본사: 매장·공급처 전체 목록
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, required this.repository, this.onChanged});
  final ChatRepository repository;
  final VoidCallback? onChanged;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> _list = [];
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // 대화 목록 실시간 갱신 (무깜빡임 폴링)
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final res = await widget.repository.conversations();
      if (!mounted) return;
      setState(() {
        _list = res.conversations;
        _loading = false;
      });
      widget.onChanged?.call();
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _open(ChatConversation c) async {
    int? convId = c.id;
    // 본사 목록에서 아직 대화방이 없으면 생성
    if (convId == null && c.partyType != null && c.partyId != null) {
      try {
        convId = await widget.repository.open(c.partyType!, c.partyId!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), behavior: SnackBarBehavior.floating));
        }
        return;
      }
    }
    if (convId == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatThreadScreen(
        repository: widget.repository,
        conversationId: convId!,
        title: c.name,
        onRead: widget.onChanged,
      ),
    ));
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('메시지')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _list.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 140),
                    Icon(Icons.forum_outlined, size: 48, color: AppColors.inkSoft),
                    SizedBox(height: 12),
                    Center(child: Text('대화가 없습니다', style: TextStyle(color: AppColors.inkSoft))),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _Row(conv: _list[i], onTap: () => _open(_list[i])),
                  ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.conv, required this.onTap});
  final ChatConversation conv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: AppColors.mango100, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(conv.name.isNotEmpty ? conv.name.characters.first : '·',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.mango800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.cream, borderRadius: BorderRadius.circular(6)),
                      child: Text(conv.label,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(conv.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(conv.lastMessage ?? '대화를 시작하세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conv.lastAt != null)
                  Text(conv.lastAt!.length >= 16 ? conv.lastAt!.substring(5, 16) : conv.lastAt!,
                      style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                const SizedBox(height: 6),
                if (conv.unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.accent, borderRadius: BorderRadius.circular(100)),
                    child: Text('${conv.unread}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
