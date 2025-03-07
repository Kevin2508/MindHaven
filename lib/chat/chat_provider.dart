import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatProvider with ChangeNotifier {
  // Map to store chat history for each session
  final Map<String, List<Map<String, dynamic>>> _sessions = {};
  String _currentSessionId = "Session 1"; // Default session

  // User details fetched from Supabase
  String? userName;
  String? profileImageUrl;

  // Get the current session's messages
  List<Map<String, dynamic>> get messages => _sessions[_currentSessionId] ?? [];

  // Get all session IDs
  List<String> get sessionIds => _sessions.keys.toList();

  // Get the current session ID
  String get currentSessionId => _currentSessionId;

  // Switch to a specific session
  void switchSession(String sessionId) {
    if (!_sessions.containsKey(sessionId)) {
      _sessions[sessionId] = []; // Create a new session if it doesn't exist
    }
    _currentSessionId = sessionId;
    notifyListeners();
  }

  // Add a message to the current session
  void addMessage(String role, String content) {
    _sessions[_currentSessionId] ??= []; // Ensure the session exists
    _sessions[_currentSessionId]!.add({"role": role, "content": content});
    saveSessions();
    notifyListeners();
  }

  // Clear the current session's messages
  void clearMessages() {
    _sessions[_currentSessionId]?.clear();
    notifyListeners();
  }

  // Delete a session
  void deleteSession(String sessionId) {
    if (_sessions.containsKey(sessionId)) {
      _sessions.remove(sessionId);
      if (_currentSessionId == sessionId && _sessions.isNotEmpty) {
        _currentSessionId = _sessions.keys.first; // Switch to another session
      } else if (_sessions.isEmpty) {
        _currentSessionId = "Session 1"; // Default session
        _sessions[_currentSessionId] = [];
      }
      saveSessions();
      notifyListeners();
    }
  }

  // Save sessions to local storage using shared_preferences
  Future<void> saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonSessions = _sessions.map(
            (key, value) => MapEntry(key, value.map((msg) => jsonEncode(msg)).toList()),
      );
      await prefs.setString('chat_sessions', jsonEncode(jsonSessions));
      await prefs.setString('user_name', userName ?? ""); // Save user name
      await prefs.setString('profile_image_url', profileImageUrl ?? ""); // Save profile image URL
    } catch (e) {
      print('Error saving sessions: $e');
    }
  }

  // Load sessions from local storage using shared_preferences
  Future<void> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonSessions = prefs.getString('chat_sessions');
      if (jsonSessions != null) {
        final decodedSessions = Map<String, dynamic>.from(jsonDecode(jsonSessions));
        _sessions.clear();
        _sessions.addAll(decodedSessions.map(
              (key, value) => MapEntry(key, (value as List).map((msg) => Map<String, dynamic>.from(jsonDecode(msg))).toList()),
        ));
      }
      userName = prefs.getString('user_name') ?? "User"; // Load user name
      profileImageUrl = prefs.getString('profile_image_url') ?? "https://via.placeholder.com/64"; // Load profile image URL
      notifyListeners();
    } catch (e) {
      print('Error loading sessions: $e');
    }
  }

  // Fetch user details from Supabase
  Future<void> fetchUserDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch user details from the 'profiles' table
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single()
          .catchError((e) {
        print('Error fetching profile: $e');
        return null;
      });

      setState(() {
        userName = response?['full_name']?.split(' ')?.first ??
            user.email?.split('@')[0] ??
            'User'; // Default to email or "User"
        profileImageUrl = response?['avatar_url'] ??
            'https://via.placeholder.com/64'; // Default placeholder image
      });
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        userName = "User";
        profileImageUrl = "https://via.placeholder.com/64";
      });
    }
  }

  // Helper method to update state and notify listeners
  void setState(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}