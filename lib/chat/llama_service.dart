import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AzureLlamaService {
  final String apiKey;
  final String endpoint = "https://models.inference.ai.azure.com";
  final String modelName = "Llama-3.2-11B-Vision-Instruct";

  AzureLlamaService({required this.apiKey});

  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/chat/completions"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": modelName,
          "messages": [
            {
              "role": "system",
              "content": """
You are a compassionate mental health assistant. Your goal is to help users feel heard, understood, and supported.
- Use empathetic language and avoid judgment.
- Ask open-ended questions to encourage reflection.
- Offer suggestions for coping strategies if appropriate.
- If the user expresses severe distress, gently recommend professional help.
- Maintain confidentiality and prioritize the user's well-being.
"""
            },
            ...messages, // Include the full chat history
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with Azure Llama API: $e');
    }
  }
}