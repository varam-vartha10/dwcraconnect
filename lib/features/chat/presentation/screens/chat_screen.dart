import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend({String inputMode = 'chat'}) {
    final chatState = ref.read(chatProvider);
    if (chatState.isLoading) return;

    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      if (_isListening) {
        _stopListening();
      }
      ref.read(chatProvider.notifier).sendMessage(text, inputMode: inputMode);
      _controller.clear();
      _scrollToBottom();
    }
  }

  Future<void> _toggleListening() async {
    final speechService = ref.read(speechServiceProvider);

    if (_isListening) {
      await _stopListening();
      if (_controller.text.trim().isNotEmpty) {
        _handleSend(inputMode: 'voice');
      }
    } else {
      final available = await speechService.initialize();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission or speech recognition not available')),
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
      });

      await speechService.startListening(
        onResult: (text, isFinal) {
          if (mounted) {
            setState(() {
              _controller.text = text;
            });
            if (isFinal) {
              setState(() {
                _isListening = false;
              });
              if (text.trim().isNotEmpty) {
                _handleSend(inputMode: 'voice');
              }
            }
          }
        },
      );
    }
  }

  Future<void> _stopListening() async {
    final speechService = ref.read(speechServiceProvider);
    await speechService.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chatAssistant,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.askMeAboutAccount,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => ref.read(chatProvider.notifier).clearHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildMessageBubble(chatState.messages[index]);
                    },
                  ),
          ),
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildInputArea(l10n),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: AppColors.primaryPurple.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.askMeAboutAccount,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          _buildQuickQuestions(l10n),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection(l10n.loanCategory, [
          l10n.totalLoanQue,
          l10n.remainingLoanQue,
          l10n.activeLoansQue,
        ]),
        _buildCategorySection(l10n.emiCategory, [
          l10n.nextEmiQue,
          l10n.emiAmountQue,
          l10n.emiDueQue,
        ]),
        _buildCategorySection(l10n.transactionCategory, [
          l10n.recentTransactionsQue,
          l10n.paymentHistoryQue,
        ]),
        _buildCategorySection(l10n.subsidyCategory, [
          l10n.showSubsidiesQue,
          l10n.whatSubsidiesQue,
        ]),
        _buildCategorySection(l10n.accountCategory, [
          l10n.showProfileQue,
          l10n.groupIdQue,
          l10n.showNotificationsQue,
        ]),
      ],
    );
  }

  Widget _buildCategorySection(String title, List<String> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPurple,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: questions.map((q) => _buildQuestionChip(q)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuestionChip(String question) {
    return ActionChip(
      label: Text(
        question,
        style: const TextStyle(fontSize: 13),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        ref.read(chatProvider.notifier).sendMessage(question);
        _scrollToBottom();
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.type == MessageType.user;
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primaryPurple : Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: isUser ? Colors.white60 : Colors.black38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isUser && message.suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.suggestions.map((q) => _buildQuestionChip(q)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : l10n.typeQuestionHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onSubmitted: (_) => _handleSend(inputMode: 'chat'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Microphone Button
            Container(
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : AppColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _isListening ? Colors.white : AppColors.primaryPurple,
                ),
                onPressed: _toggleListening,
              ),
            ),
            const SizedBox(width: 8),
            // Send Button
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () => _handleSend(inputMode: 'chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
