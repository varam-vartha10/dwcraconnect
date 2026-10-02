enum MessageType { user, assistant }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final List<String> suggestions;

  ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.suggestions = const [],
  });
}
