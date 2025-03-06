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

  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadSessions();
    chatProvider.fetchUserDetails();// Load saved sessions when the screen initializes
  }

  // Method to build the "Create New Session" dialog
  Widget _buildNewSessionDialog(ChatProvider chatProvider) {
    final TextEditingController _controller = TextEditingController();

    return AlertDialog(
      title: const Text("Create New Session"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: "Enter session name"),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              chatProvider.switchSession(_controller.text.trim());
              chatProvider.saveSessions(); // Persist the new session
              Navigator.pop(context); // Close the dialog
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }

  // Method to send a message to the AI chatbot
  void _sendMessage(AzureLlamaService llamaService, ChatProvider chatProvider) async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // Add user message to the current session
    chatProvider.addMessage("user", message);
    _controller.clear();

    // Send the current session's messages to the Azure Llama API
    try {
      final llamaResponse = await llamaService.sendMessage(chatProvider.messages);
      chatProvider.addMessage("assistant", llamaResponse);
      chatProvider.saveSessions(); // Persist the updated session after sending a message
    } catch (e) {
      chatProvider.addMessage("assistant", "Sorry, I couldn't process that.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final llamaService = AzureLlamaService(apiKey: AppConstants.azureApiKey); // Pass API key here

    // Fetch user details from the provider or app state
    final String userName = chatProvider.userName ?? "User"; // Default to "User" if not available
    final String userProfileImageUrl = chatProvider.profileImageUrl ?? "https://via.placeholder.com/64"; // Default placeholder image

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat"),
        backgroundColor: const Color(0xFF9BB168),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Column(
        children: [
          // Session Management Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text("Session: "),
                DropdownButton<String>(
                  value:  chatProvider.sessionIds.contains(chatProvider.currentSessionId)
                      ? chatProvider.currentSessionId
                      : chatProvider.sessionIds.isNotEmpty
                      ? chatProvider.sessionIds.first // Default to the first session if currentSessionId is invalid
                      : null,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      chatProvider.switchSession(newValue);
                    }
                  },
                  items: chatProvider.sessionIds.map((String sessionId) {
                    return DropdownMenuItem<String>(
                      value: sessionId,
                      child: Text(sessionId),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildNewSessionDialog(chatProvider),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    chatProvider.deleteSession(chatProvider.currentSessionId);
                    chatProvider.saveSessions(); // Persist the deletion of the session
                  },
                ),
              ],
            ),
          ),

          // Chat History Display
          Expanded(
            child: ListView.builder(
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                final bool isUserMessage = message["role"] == "user";

                return ListTile(
                  leading: isUserMessage
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(userProfileImageUrl), // Show user's profile photo
                  )
                      : const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/angel.png'), // AI avatar (replace with your asset)
                  ),
                  title: Text(
                    isUserMessage ? userName : "Braino", // Display username or "Braino"
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUserMessage ? Colors.blue : Colors.green,
                    ),
                  ),
                  subtitle: Text(
                    message["content"],
                    style: TextStyle(
                      color: isUserMessage ? Colors.black : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat Input Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(llamaService, chatProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}