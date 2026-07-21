import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of chat messages, ordered by timestamp
  Stream<List<ChatMessage>> getMessagesStream() {
    return _firestore
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.data());
      }).toList();
    });
  }

  // Send message with strict client-side validation and sanitization
  Future<void> sendMessage({
    required String senderName,
    required String senderEmail,
    required String text,
    required bool isVoice,
    String? voiceUrl,
    int? voiceDuration,
  }) async {
    // 1. Sanitize input to prevent XSS, HTML Injection, and Code upload
    final sanitizedText = _sanitizeAndVerifyInput(text);

    final docRef = _firestore.collection('chat_messages').doc();
    final message = ChatMessage(
      id: docRef.id,
      senderName: senderName,
      senderEmail: senderEmail,
      text: sanitizedText,
      timestamp: DateTime.now(),
      isVoice: isVoice,
      voiceUrl: voiceUrl,
      voiceDuration: voiceDuration,
    );

    await docRef.set(message.toJson());
  }

  // Strict input sanitizer to prevent code injection and exploit sharing
  String _sanitizeAndVerifyInput(String input) {
    if (input.isEmpty) return input;

    // A. Strip HTML/JS tags to prevent XSS
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>|javascript:', caseSensitive: false), '');

    // B. Detect Code Snippets / Exploit Payloads / Reverse Shell patterns
    final List<RegExp> codePatterns = [
      RegExp(r'(bash\s+-i|/bin/sh|/bin/bash|exec\s+sh|sh\s+-c)', caseSensitive: false), // Reverse shells
      RegExp(r'(nc\s+-e|netcat\s+-e)', caseSensitive: false),                          // Netcat payloads
      RegExp(r'(eval\s*\(|system\s*\(|exec\s*\(|popen\s*\()', caseSensitive: false),     // PHP/Python system executions
      RegExp(r'(powershell|iex\s*\(|new-object\s+net\.webclient)', caseSensitive: false), // PowerShell executions
      RegExp(r'(SELECT\s+.*\s+FROM|UNION\s+SELECT|INSERT\s+INTO)', caseSensitive: false), // SQLi blocks
      RegExp(r'(`{3}[\s\S]*`{3})'),                                                    // Markdown code blocks
    ];

    for (var pattern in codePatterns) {
      if (pattern.hasMatch(sanitized)) {
        // Censor code sharing to prevent active exploit sharing in chat
        sanitized = '[SECURITY NOTICE: Active scripts and code sharing are restricted to prevent exploitation]';
        break;
      }
    }

    return sanitized;
  }
}
