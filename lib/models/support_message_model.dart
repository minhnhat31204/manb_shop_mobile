class SupportMessageModel {
  final int messageId;
  final int conversationId;
  final int? senderUserId;
  final String senderRole; // 'Customer', 'Admin', 'AI'
  final String senderName;
  final String message;
  final DateTime createdAt;

  SupportMessageModel({
    required this.messageId,
    required this.conversationId,
    this.senderUserId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      messageId: json['MessageID'] is int
          ? json['MessageID']
          : int.tryParse(json['MessageID']?.toString() ?? '0') ?? 0,
      conversationId: json['ConversationID'] is int
          ? json['ConversationID']
          : int.tryParse(json['ConversationID']?.toString() ?? '0') ?? 0,
      senderUserId: json['SenderUserID'] != null
          ? (json['SenderUserID'] is int
              ? json['SenderUserID']
              : int.tryParse(json['SenderUserID'].toString()))
          : null,
      senderRole: (json['SenderRole'] ?? 'Customer').toString(),
      senderName: (json['SenderName'] ?? '').toString(),
      message: (json['Message'] ?? '').toString(),
      createdAt: json['CreatedAt'] != null
          ? DateTime.tryParse(json['CreatedAt'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MessageID': messageId,
      'ConversationID': conversationId,
      'SenderUserID': senderUserId,
      'SenderRole': senderRole,
      'SenderName': senderName,
      'Message': message,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }

  bool get isCustomer => senderRole == 'Customer';
  bool get isAI => senderRole == 'AI';
  bool get isAdmin => senderRole == 'Admin';
}
