import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/voice_service.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? lastInputMode;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
    this.lastInputMode = 'chat',
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? lastInputMode,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastInputMode: lastInputMode ?? this.lastInputMode,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final TtsService _ttsService;

  ChatNotifier(this._repository, this._ttsService) : super(ChatState(messages: []));

  Future<void> sendMessage(String text, {String inputMode = 'chat'}) async {
    final userMessage = ChatMessage(
      text: text,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    // 1. Update state with user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
      lastInputMode: inputMode,
    );

    try {
      // 2. Call backend
      final result = await _repository.sendMessage(text, inputMode: inputMode);
      
      final reply = result['reply'] as String;
      final language = result['language'] as String?;
      final suggestions = List<String>.from(result['suggestions'] ?? []);

      final assistantMessage = ChatMessage(
        text: reply,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        suggestions: suggestions,
      );

      // 3. Update state
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );

      // 4. Speak response aloud if input mode was voice
      if (inputMode == 'voice') {
        await _ttsService.speak(reply, language: language);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void stopSpeech() {
    _ttsService.stop();
  }

  void clearHistory() {
    _ttsService.stop();
    state = ChatState(messages: []);
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository());
final ttsServiceProvider = Provider((ref) => TtsService());
final speechServiceProvider = Provider((ref) => SpeechService());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  return ChatNotifier(repository, ttsService);
});
