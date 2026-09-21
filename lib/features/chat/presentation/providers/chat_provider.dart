import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatNotifier(this._repository) : super(ChatState(messages: []));

  Future<void> sendMessage(String text) async {
    final userMessage = ChatMessage(
      text: text,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final result = await _repository.sendMessage(text);
      final assistantMessage = ChatMessage(
        text: result['reply'],
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearHistory() {
    state = ChatState(messages: []);
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});
