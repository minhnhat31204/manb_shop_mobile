import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/support_message_model.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';

class ChatScreen extends StatefulWidget {
  final ChatChannel initialChannel;

  const ChatScreen({
    super.key,
    this.initialChannel = ChatChannel.ai,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _timeFormat = DateFormat('HH:mm');

  final List<String> _quickAiPrompts = [
    '🎮 Laptop chơi game Valorant, LOL mượt',
    '💻 Laptop sinh viên / văn phòng mỏng nhẹ',
    '🎨 Laptop đồ họa & lập trình màn đẹp',
    '💰 Tư vấn máy tầm 15 - 20 triệu',
    '📦 Chính sách bảo hành & giao hàng hỏa tốc',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final user = userProvider.user;
      final userId = userProvider.currentUserId;
      final userName = user?['FullName'] ?? user?['Username'] ?? 'Khách hàng Mobile';
      final userEmail = user?['Email'];

      chatProvider.updateUserInfo(userId: userId, name: userName, email: userEmail);
      chatProvider.selectChannel(widget.initialChannel);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(text).then((success) {
      if (success && quickText == null) {
        _textController.clear();
      }
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, child) {
        // Tự động cuộn xuống khi có tin nhắn mới
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients &&
              _scrollController.position.maxScrollExtent - _scrollController.offset < 120) {
            _scrollToBottom();
          }
        });

        final isAi = chat.activeChannel == ChatChannel.ai;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E40AF),
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Text(
                        isAi ? '🤖' : '👨‍💼',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E40AF), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAi ? 'Trợ lý DEVORA AI' : 'Chăm sóc khách hàng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isAi
                            ? 'Tư vấn thông minh & báo giá 24/7'
                            : 'Nhân viên trực tuyến sẵn sàng hỗ trợ',
                        style: TextStyle(
                          color: Colors.blue[100],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Nút chuyển đổi chế độ Chat AI / CSKH nhanh
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: PopupMenuButton<ChatChannel>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'Đổi kênh trò chuyện',
                  onSelected: (channel) => chat.selectChannel(channel),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ChatChannel.ai,
                      child: Row(
                        children: [
                          const Text('🤖 ', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Trợ lý AI 24/7',
                            style: TextStyle(
                              fontWeight: isAi ? FontWeight.bold : FontWeight.normal,
                              color: isAi ? const Color(0xFF1E40AF) : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ChatChannel.staff,
                      child: Row(
                        children: [
                          const Text('👨‍💼 ', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Gặp nhân viên CSKH',
                            style: TextStyle(
                              fontWeight: !isAi ? FontWeight.bold : FontWeight.normal,
                              color: !isAi ? const Color(0xFF1E40AF) : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(42),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildChannelTab(
                        title: '🤖 Trợ lý AI',
                        isSelected: isAi,
                        onTap: () => chat.selectChannel(ChatChannel.ai),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChannelTab(
                        title: '👨‍💼 Nhân viên CSKH',
                        isSelected: !isAi,
                        onTap: () => chat.selectChannel(ChatChannel.staff),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              if (chat.errorMessage != null)
                Container(
                  color: Colors.red[50],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chat.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: chat.isLoading && chat.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5),
                            SizedBox(height: 12),
                            Text(
                              'Đang kết nối hệ thống hỗ trợ...',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : _buildMessagesList(chat),
              ),
              if (chat.isSending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAi
                            ? 'Trợ lý AI đang tra cứu & soạn câu trả lời...'
                            : 'Đang gửi...',
                        style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              _buildBottomInputBar(chat),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E40AF) : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatProvider chat) {
    if (chat.messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                chat.activeChannel == ChatChannel.ai
                    ? '👋 Dạ DEVORA xin chào quý khách! Em là Trợ lý AI chuyên tư vấn laptop & máy tính. Em có thể hỗ trợ quý khách chọn máy theo ngân sách, phân tích cấu hình, kiểm tra tồn kho và giải đáp chính sách cửa hàng 24/7 ạ.'
                    : '👋 Dạ DEVORA xin chào quý khách! Quý khách cần hỗ trợ kiểm tra đơn hàng, bảo hành hay tư vấn sản phẩm gì ạ? Nhân viên CSKH sẽ phản hồi ngay.',
                style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF334155)),
              ),
            ),
            if (chat.activeChannel == ChatChannel.ai) ...[
              const SizedBox(height: 18),
              const Text(
                '💡 GỢI Ý CÂU HỎI NHANH:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAiPrompts.map((prompt) {
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    label: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _sendMessage(prompt),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final msg = chat.messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(SupportMessageModel msg) {
    final bool isUser = msg.isCustomer;
    final bool isAi = msg.isAI;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: isAi ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE),
              child: Text(isAi ? '🤖' : '👨‍💼', style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1E40AF)
                    : isAi
                        ? const Color(0xFFFAF5FF)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF1E40AF)
                      : isAi
                          ? const Color(0xFFE9D5FF)
                          : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        isAi ? '🤖 Trợ lý DEVORA AI' : (msg.senderName.isNotEmpty ? msg.senderName : 'Nhân viên CSKH'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAi ? const Color(0xFF7E22CE) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: isUser ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeFormat.format(msg.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.blue[100] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar(ChatProvider chat) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn hỗ trợ...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF1E40AF),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
