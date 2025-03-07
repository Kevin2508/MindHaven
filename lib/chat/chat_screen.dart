import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/llama_service.dart';
import '../chat/chat_provider.dart';
import '../constants.dart'; // Import for API key

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // For scrolling chat

  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadSessions();
    chatProvider.fetchUserDetails();
  }

  // New Session Dialog
  Widget _buildNewSessionDialog(ChatProvider chatProvider) {
    final TextEditingController _sessionController = TextEditingController();

    return AlertDialog(
      backgroundColor: Color(0xfff4eee0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Create New Session",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xff5e3e2b),
        ),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _sessionController,
          decoration: InputDecoration(
            hintText: "Enter session name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: Color(0xff5e3e2b)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_sessionController.text.trim().isNotEmpty) {
              chatProvider.switchSession(_sessionController.text.trim());
              chatProvider.saveSessions();
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff5e3e2b),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            "Create",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Send Message
  void _sendMessage(AzureLlamaService llamaService, ChatProvider chatProvider) async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    chatProvider.addMessage("user", message);
    _controller.clear();
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // Scroll to bottom

    try {
      final llamaResponse = await llamaService.sendMessage(chatProvider.messages);
      chatProvider.addMessage("assistant", llamaResponse);
      chatProvider.saveSessions();
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // Scroll after response
    } catch (e) {
      chatProvider.addMessage("assistant", "Sorry, I couldn't process that.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final llamaService = AzureLlamaService(apiKey: AppConstants.azureApiKey);
    final String userName = chatProvider.userName ?? "User";
    final String userProfileImageUrl = chatProvider.profileImageUrl ?? "https://via.placeholder.com/64";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xfff4eee0), // Beige from your theme
              Color(0xffe0d8c8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xff9bb068), // Brown from HealthJournalPage
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                      tooltip: 'Back',
                    ),
                    Text(
                      "AI Chat",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 48), // Spacer for symmetry
                  ],
                ),
              ),
              // Session Management
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.1),
                child: Row(
                  children: [
                    Text(
                      "Session: ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff5e3e2b),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: chatProvider.sessionIds.contains(chatProvider.currentSessionId)
                            ? chatProvider.currentSessionId
                            : chatProvider.sessionIds.isNotEmpty
                            ? chatProvider.sessionIds.first
                            : null,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            chatProvider.switchSession(newValue);
                          }
                        },
                        items: chatProvider.sessionIds.map((String sessionId) {
                          return DropdownMenuItem<String>(
                            value: sessionId,
                            child: Text(
                              sessionId,
                              style: TextStyle(color: Color(0xff5e3e2b)),
                            ),
                          );
                        }).toList(),
                        underline: SizedBox(), // Remove default underline
                        dropdownColor: Color(0xfff4eee0),
                      ),
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.add, color: Color(0xff5e3e2b), size: 28),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _buildNewSessionDialog(chatProvider),
                        );
                      },
                      tooltip: 'New Session',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent, size: 28),
                      onPressed: () {
                        chatProvider.deleteSession(chatProvider.currentSessionId);
                        chatProvider.saveSessions();
                      },
                      tooltip: 'Delete Session',
                    ),
                  ],
                ),
              ),
              // Chat History
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final bool isUserMessage = message["role"] == "user";

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                          isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isUserMessage)
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage('assets/images/angel.png'),
                              ),
                            SizedBox(width: isUserMessage ? 0 : 12),
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUserMessage
                                      ? Color(0xff926247).withOpacity(0.2)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isUserMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUserMessage ? userName : "Braino",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isUserMessage
                                            ? Color(0xff5e3e2b)
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      message["content"],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: isUserMessage ? 12 : 0),
                            if (isUserMessage)
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(userProfileImageUrl),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Input Area
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.9),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.send, color: Color(0xff5e3e2b), size: 28),
                      onPressed: () => _sendMessage(llamaService, chatProvider),
                      splashRadius: 24,
                      tooltip: 'Send',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}