import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/chat_repository.dart';
import '../../models/chat.dart';
import '../../theme/app_colors.dart';

/// 1:1 채팅 스레드 (폴링으로 신규 메시지 수신).
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.repository,
    required this.conversationId,
    required this.title,
    this.onRead,
  });

  final ChatRepository repository;
  final int conversationId;
  final String title;
  final VoidCallback? onRead;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _me = -1;
  int _lastId = 0;
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(milliseconds: 2500), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final res = await widget.repository
          .messages(widget.conversationId, after: initial ? null : _lastId);
      if (!mounted) return;
      if (res.messages.isNotEmpty) {
        setState(() {
          _me = res.me;
          _messages.addAll(res.messages);
          _lastId = _messages.last.id;
        });
        _scrollToBottom();
        widget.onRead?.call();
      } else if (initial) {
        setState(() => _me = res.me);
      }
    } catch (_) {
      // 폴링 실패는 조용히 무시
    } finally {
      if (initial && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final msg = await widget.repository.send(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _lastId = msg.id;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
        _input.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendFile(String path) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final msg = await widget.repository
          .sendAttachment(widget.conversationId, filePath: path);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _lastId = msg.id;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attachSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
              title: const Text('사진 촬영'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      final x = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2000,
      );
      if (x != null) await _sendFile(x.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('첨부 실패: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('첫 메시지를 보내보세요',
                            style: TextStyle(color: AppColors.inkSoft)))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) =>
                            _Bubble(message: _messages[i], mine: _messages[i].userId == _me),
                      ),
          ),
          _InputBar(
              controller: _input,
              sending: _sending,
              onSend: _send,
              onAttach: _attachSheet),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 3),
              child: Text(message.senderName,
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ),
          Row(
            mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (mine && message.time != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(message.time!,
                      style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                ),
              Flexible(child: _content(context)),
              if (!mine && message.time != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(message.time!,
                      style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.72;
    final items = <Widget>[];

    if (message.attachmentUrl != null) {
      if (message.attachmentIsImage) {
        items.add(GestureDetector(
          onTap: () => _openUrl(message.attachmentUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW, maxHeight: 240),
              child: Image.network(
                message.attachmentUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (c, w, p) => p == null
                    ? w
                    : Container(
                        width: 160, height: 120, color: AppColors.mango50,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent)),
                errorBuilder: (_, _, _) => _fileChip(),
              ),
            ),
          ),
        ));
      } else {
        items.add(GestureDetector(
            onTap: () => _openUrl(message.attachmentUrl!), child: _fileChip()));
      }
    }

    if (message.body != null && message.body!.isNotEmpty) {
      items.add(Container(
        constraints: BoxConstraints(maxWidth: maxW),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: mine ? null : Border.all(color: AppColors.line),
        ),
        child: Text(message.body!,
            style: TextStyle(
                fontSize: 14, height: 1.4, color: mine ? Colors.white : AppColors.ink)),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) return items.first;
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        items[0],
        const SizedBox(height: 4),
        items[1],
      ],
    );
  }

  Widget _fileChip() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: mine ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: mine ? null : Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 20, color: mine ? Colors.white : AppColors.mango700),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message.attachmentName ?? '첨부파일',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: mine ? Colors.white : AppColors.ink)),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          6, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          IconButton(
            onPressed: sending ? null : onAttach,
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
            tooltip: '첨부',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: '메시지 입력',
                filled: true,
                fillColor: AppColors.cream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: sending
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
