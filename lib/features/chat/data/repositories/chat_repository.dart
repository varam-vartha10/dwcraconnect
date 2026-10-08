import '../../../../core/network/api_service.dart';
import '../../../../core/network/cache_service.dart';

class ChatRepository {
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String inputMode = 'chat',
    String? conversationId,
  }) async {
    try {
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
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('internet connection') ||
          e.toString().contains('TimeoutException')) {
        return await _generateOfflineResponse(message);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _generateOfflineResponse(String message) async {
    final activeUser = await CacheService.getActiveUser() ?? 'guest';
    final cachedLoans = await CacheService.get(userId: activeUser, key: 'loans_$activeUser');
    final cachedEmis = await CacheService.get(userId: activeUser, key: 'emis_$activeUser');
    final cachedSubs = await CacheService.get(userId: activeUser, key: 'subsidies_$activeUser');

    final lastSyncIso = cachedLoans?['lastSyncedIso'] ?? cachedEmis?['lastSyncedIso'] ?? cachedSubs?['lastSyncedIso'];
    String syncText = '';
    if (lastSyncIso != null) {
      try {
        final dt = DateTime.parse(lastSyncIso.toString());
        syncText = ' (Last synced: ${dt.day}/${dt.month}/${dt.year})';
      } catch (_) {}
    }

    final lower = message.toLowerCase();

    if (cachedLoans != null && cachedLoans['data'] is List && (cachedLoans['data'] as List).isNotEmpty) {
      final loanList = cachedLoans['data'] as List;
      final loanMap = Map<String, dynamic>.from(loanList[0] as Map);
      final principal = ((loanMap['principalAmount'] ?? 0) as num).toDouble();
      final remaining = ((loanMap['remainingAmount'] ?? principal) as num).toDouble();

      if (lower.contains('loan') || lower.contains('balance') || lower.contains('remaining') || lower.contains('left')) {
        return {
          'reply': 'Your last synchronized remaining loan balance was ₹${remaining.toStringAsFixed(2)}$syncText. You are currently offline, so this may not reflect recent changes.',
          'language': 'en',
          'suggestions': ['When is my next EMI?', 'Show my transactions'],
          'intent': 'offline_loan_balance',
        };
      }
    }

    if (cachedEmis != null && cachedEmis['data'] is List && (cachedEmis['data'] as List).isNotEmpty) {
      final emiList = cachedEmis['data'] as List;
      final unpaid = emiList.where((e) => (e as Map)['status'] != 'paid').toList();
      if (unpaid.isNotEmpty) {
        final nextEmi = Map<String, dynamic>.from(unpaid[0] as Map);
        final amt = ((nextEmi['amount'] ?? 0) as num).toDouble();
        if (lower.contains('emi') || lower.contains('next') || lower.contains('due')) {
          return {
            'reply': 'Your last synchronized next EMI is ₹${amt.toStringAsFixed(2)}$syncText. You are currently offline, so please connect to the internet to complete payments.',
            'language': 'en',
            'suggestions': ['What is my remaining loan?', 'Show my subsidies'],
            'intent': 'offline_next_emi',
          };
        }
      }
    }

    return {
      'reply': 'Your account data is not available offline yet$syncText. Please connect to the internet to synchronize your account.',
      'language': 'en',
      'suggestions': ['Retry when online'],
      'intent': 'offline_no_data',
    };
  }
}
