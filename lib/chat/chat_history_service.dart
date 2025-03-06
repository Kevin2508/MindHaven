import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatHistoryService {
  static const String _chatHistoryKey = "chat_history";

  // Save chat history to local storage
  Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMessages = messages.map((msg) => jsonEncode(msg)).toList();
    await prefs.setStringList(_chatHistoryKey, jsonMessages);
  }

  // Load chat history from local storage
  Future<List<Map<String, dynamic>>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMessages = prefs.getStringList(_chatHistoryKey) ?? [];
    return jsonMessages.map((json) => Map<String, dynamic>.from(jsonDecode(json))).toList();
  }
}