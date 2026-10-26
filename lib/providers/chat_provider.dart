import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/support_message_model.dart';
import '../services/api_service.dart';

enum ChatChannel { ai, staff }

class ChatProvider extends ChangeNotifier {
  ChatChannel _activeChannel = ChatChannel.ai;
  ChatChannel get activeChannel => _activeChannel;

  int? _conversationIdAi;
  int? _conversationIdStaff;

  int? get currentConversationId =>
      _activeChannel == ChatChannel.ai ? _conversationIdAi : _conversationIdStaff;

  final List<SupportMessageModel> _messages = [];
  List<SupportMessageModel> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _pollingTimer;

  // Key định danh khách vãng lai (khớp quy chuẩn web VISITOR_KEY)
  static const String _visitorKeyPrefix = 'devora-support-visitor';
  String? _visitorKeyAi;
  String? _visitorKeyStaff;

  int? _userId;
  String? _userName;
  String? _userEmail;

  ChatProvider() {
    _initVisitorKeys();
  }

  Future<void> _initVisitorKeys() async {
    final prefs = await SharedPreferences.getInstance();
    const uuid = Uuid();

    _visitorKeyAi = prefs.getString('$_visitorKeyPrefix-ai');
    if (_visitorKeyAi == null) {
      _visitorKeyAi = 'flutter-visitor-${uuid.v4()}';
      await prefs.setString('$_visitorKeyPrefix-ai', _visitorKeyAi!);
    }

    _visitorKeyStaff = prefs.getString('$_visitorKeyPrefix-staff');
    if (_visitorKeyStaff == null) {
      _visitorKeyStaff = 'flutter-visitor-${uuid.v4()}';
      await prefs.setString('$_visitorKeyPrefix-staff', _visitorKeyStaff!);
    }
  }

  void updateUserInfo({int? userId, String? name, String? email}) {
    if (_userId != userId) {
      _userId = userId;
      _userName = name;
      _userEmail = email;
      // Reset cuộc hội thoại nếu thay đổi tài khoản
      _conversationIdAi = null;
      _conversationIdStaff = null;
      _messages.clear();
      notifyListeners();
    } else {
      _userName = name ?? _userName;
      _userEmail = email ?? _userEmail;
    }
  }

  String _getVisitorKey(ChatChannel channel) {
    if (channel == ChatChannel.ai) {
      return _visitorKeyAi ?? 'flutter-visitor-ai';
    } else {
      return _visitorKeyStaff ?? 'flutter-visitor-staff';
    }
  }

  Future<void> selectChannel(ChatChannel channel) async {
    if (_activeChannel == channel && _messages.isNotEmpty) return;
    _activeChannel = channel;
    _errorMessage = null;
    _messages.clear();
    notifyListeners();

    await openConversation();
  }

  Future<void> openConversation() async {
    _stopPolling();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final channelKey = _activeChannel;
      final existingId = channelKey == ChatChannel.ai ? _conversationIdAi : _conversationIdStaff;

      if (existingId != null) {
        await fetchMessages(existingId);
        _startPolling(existingId);
        _isLoading = false;
        notifyListeners();
        return;
      }

      final visitorKey = _getVisitorKey(channelKey);
      final res = await ApiService.openSupportConversation(
        userId: _userId,
        visitorKey: _userId != null ? null : visitorKey,
        name: _userName ?? 'Khách hàng Mobile',
        email: _userEmail,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final conversation = data['conversation'];
        final convId = conversation['ConversationID'] is int
            ? conversation['ConversationID']
            : int.tryParse(conversation['ConversationID'].toString()) ?? 0;

        if (channelKey == ChatChannel.ai) {
          _conversationIdAi = convId;
        } else {
          _conversationIdStaff = convId;
        }

        await fetchMessages(convId);
        _startPolling(convId);
      } else {
        _errorMessage = 'Không thể kết nối cuộc trò chuyện (${res.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối máy chủ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    try {
      final visitorKey = _getVisitorKey(_activeChannel);
      final res = await ApiService.getSupportMessages(
        conversationId,
        userId: _userId,
        visitorKey: _userId != null ? null : visitorKey,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rawMsgs = data['messages'] ?? [];
        final newMsgs = rawMsgs.map((m) => SupportMessageModel.fromJson(m)).toList();

        // Kiểm tra xem có tin nhắn mới không để tránh re-render không cần thiết
        if (_messages.length != newMsgs.length ||
            (_messages.isNotEmpty &&
                newMsgs.isNotEmpty &&
                _messages.last.messageId != newMsgs.last.messageId)) {
          _messages.clear();
          _messages.addAll(newMsgs);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ChatProvider fetchMessages error: $e');
    }
  }

  void _startPolling(int conversationId) {
    _stopPolling();
    // Đồng bộ thời gian thực mỗi 3 giây (y hệt như cơ chế polling bên Web SupportWidget)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchMessages(conversationId);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> sendMessage(String text) async {
    final message = text.trim();
    final convId = currentConversationId;
    if (message.isEmpty || convId == null || _isSending) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final visitorKey = _getVisitorKey(_activeChannel);
      final res = await ApiService.sendSupportMessage(
        convId,
        message: message,
        userId: _userId,
        visitorKey: _userId != null ? null : visitorKey,
        senderName: _userName ?? 'Khách hàng',
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['message'] != null) {
          final sentMsg = SupportMessageModel.fromJson(data['message']);
          if (!_messages.any((m) => m.messageId == sentMsg.messageId)) {
            _messages.add(sentMsg);
            notifyListeners();
          }
        }

        // Nếu đang ở kênh AI, tự động gọi endpoint AI trả lời
        if (_activeChannel == ChatChannel.ai) {
          _requestAiReply(convId);
        }

        _isSending = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Gửi tin nhắn thất bại';
      }
    } catch (e) {
      _errorMessage = 'Lỗi gửi tin: $e';
    } finally {
      _isSending = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> _requestAiReply(int convId) async {
    try {
      final visitorKey = _getVisitorKey(ChatChannel.ai);
      final res = await ApiService.requestSupportAiReply(
        convId,
        userId: _userId,
        visitorKey: _userId != null ? null : visitorKey,
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['message'] != null) {
          final aiMsg = SupportMessageModel.fromJson(data['message']);
          if (!_messages.any((m) => m.messageId == aiMsg.messageId)) {
            _messages.add(aiMsg);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('AI reply request error: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
