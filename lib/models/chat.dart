// 채팅 모델 (본사 ↔ 매장/공급처).

class ChatConversation {
  final int? id; // 본사 목록에서 아직 대화방 미생성이면 null
  final String? partyType; // store | supplier (본사 목록용)
  final int? partyId;
  final String name;
  final String label; // 본사 / 매장 / 공급처
  final String? lastMessage;
  final String? lastAt;
  final int unread;

  const ChatConversation({
    required this.id,
    required this.partyType,
    required this.partyId,
    required this.name,
    required this.label,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> j) => ChatConversation(
        id: j['id'] as int?,
        partyType: j['party_type'] as String?,
        partyId: j['party_id'] as int?,
        name: j['name'] as String? ?? '',
        label: j['label'] as String? ?? '',
        lastMessage: j['last_message'] as String?,
        lastAt: j['last_at'] as String?,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  final int id;
  final int? userId;
  final String senderRole;
  final String senderName;
  final String? body;
  final String? time;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool attachmentIsImage;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.senderRole,
    required this.senderName,
    required this.body,
    required this.time,
    required this.attachmentUrl,
    required this.attachmentName,
    required this.attachmentIsImage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        userId: j['user_id'] as int?,
        senderRole: j['sender_role'] as String? ?? '',
        senderName: j['sender_name'] as String? ?? '',
        body: j['body'] as String?,
        time: j['time'] as String?,
        attachmentUrl: j['attachment_url'] as String?,
        attachmentName: j['attachment_name'] as String?,
        attachmentIsImage: j['attachment_is_image'] as bool? ?? false,
      );
}
