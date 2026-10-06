import '../../../../core/network/api_service.dart';

class ChatRepository {
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String inputMode = 'chat',
    String? conversationId,
  }) async {
    final response = await ApiService.post('/chat', {
      'message': message,
      'inputMode': inputMode,
      ...?conversationId != null ? {'conversationId': conversationId} : null,
    });

    if (response['success'] == true) {
      return {
        'reply': response['reply'],
        'language': response['language'],
        'suggestions': List<String>.from(response['suggestions'] ?? []),
        'intent': response['intent'],
      };
    } else {
      throw Exception(response['message'] ?? 'Failed to get response from assistant');
    }
  }
}
