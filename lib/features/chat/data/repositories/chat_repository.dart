import '../../../../core/network/api_service.dart';

class ChatRepository {
  Future<Map<String, dynamic>> sendMessage(String message) async {
    final response = await ApiService.post('/chat', {
      'message': message,
    });

    if (response['success'] == true) {
      return {
        'reply': response['reply'],
        'language': response['language'],
        'suggestions': List<String>.from(response['suggestions'] ?? []),
      };
    } else {
      throw Exception(response['message'] ?? 'Failed to get response from assistant');
    }
  }
}
