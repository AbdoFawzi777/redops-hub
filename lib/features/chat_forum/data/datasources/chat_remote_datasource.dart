import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_group.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of chat messages for a specific group, ordered by timestamp
  Stream<List<ChatMessage>> getMessagesStream(String groupId) {
    return _firestore
        .collection('chat_messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.data());
      }).toList();
    });
  }

  // Stream of active groups where the user is a member or owner
  Stream<List<ChatGroup>> getGroupsStream(String userEmail) {
    // Automatically check/create default public lobby group
    initializeDefaultLobby();

    return _firestore
        .collection('chat_groups')
        .snapshots()
        .map((snapshot) {
      final List<ChatGroup> list = [];
      for (var doc in snapshot.docs) {
        final group = ChatGroup.fromJson(doc.data());
        // Users can access: default 'lobby', owned groups, or groups where they are listed as members
        if (group.id == 'lobby' || group.ownerEmail == userEmail || group.members.contains(userEmail)) {
          list.add(group);
        }
      }
      // If list is empty, return lobby as default fallback locally
      if (list.isEmpty) {
        list.add(ChatGroup(
          id: 'lobby',
          name: 'Public Lobby',
          description: 'Global encrypted operator lounge.',
          ownerEmail: 'system@redopshub.com',
          members: [],
        ));
      }
      return list;
    });
  }

  // Initialize public lobby group in Firestore
  Future<void> initializeDefaultLobby() async {
    try {
      final doc = await _firestore.collection('chat_groups').doc('lobby').get();
      if (!doc.exists) {
        await _firestore.collection('chat_groups').doc('lobby').set({
          'id': 'lobby',
          'name': 'Public Lobby',
          'description': 'Global encrypted operator lounge.',
          'ownerEmail': 'system@redopshub.com',
          'members': [],
        });
      }
    } catch (e) {
      developer.log('Failed to initialize lobby', name: 'ChatRemote', error: e);
    }
  }

  // Create new WhatsApp-style custom group with owner/moderator
  Future<void> createGroup({
    required String name,
    required String description,
    required String ownerEmail,
    required List<String> members,
  }) async {
    final docRef = _firestore.collection('chat_groups').doc();
    final group = ChatGroup(
      id: docRef.id,
      name: name,
      description: description,
      ownerEmail: ownerEmail,
      members: members,
    );
    await docRef.set(group.toJson());
  }

  // Send message with strict client-side validation, sanitization, and moderation
  Future<void> sendMessage({
    required String senderName,
    required String senderEmail,
    required String text,
    required bool isVoice,
    required String groupId,
    String? voiceUrl,
    int? voiceDuration,
  }) async {
    // 1. Moderate message for profanity, politics, and military
    final moderatedText = _moderateAndSanitizeInput(text);

    // 2. Resolve Sender rank tag dynamically based on findings count
    final rank = await _resolveOperatorRank(senderEmail);

    final docRef = _firestore.collection('chat_messages').doc();
    final message = ChatMessage(
      id: docRef.id,
      senderName: senderName,
      senderEmail: senderEmail,
      text: moderatedText,
      timestamp: DateTime.now(),
      isVoice: isVoice,
      voiceUrl: voiceUrl,
      voiceDuration: voiceDuration,
      groupId: groupId,
      senderRank: rank,
    );

    await docRef.set(message.toJson());
  }

  // Strict moderation algorithm covering profanity, politics, and military domains
  String _moderateAndSanitizeInput(String input) {
    if (input.isEmpty) return input;

    // A. Strip HTML/JS tags to prevent XSS
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>|javascript:', caseSensitive: false), '');

    // B. Security code block checks
    final List<RegExp> codePatterns = [
      RegExp(r'(bash\s+-i|/bin/sh|/bin/bash|exec\s+sh|sh\s+-c)', caseSensitive: false),
      RegExp(r'(nc\s+-e|netcat\s+-e)', caseSensitive: false),
      RegExp(r'(eval\s*\(|system\s*\(|exec\s*\(|popen\s*\()', caseSensitive: false),
      RegExp(r'(powershell|iex\s*\(|new-object\s+net\.webclient)', caseSensitive: false),
      RegExp(r'(SELECT\s+.*\s+FROM|UNION\s+SELECT|INSERT\s+INTO)', caseSensitive: false),
      RegExp(r'(`{3}[\s\S]*`{3})'),
    ];

    for (var pattern in codePatterns) {
      if (pattern.hasMatch(sanitized)) {
        return '[SECURITY NOTICE: Active scripts and code sharing are restricted to prevent exploitation]';
      }
    }

    // C. Moderation Domain blocklists (Profanity, Politics, Military)
    final List<String> blocklist = [
      // English Profanity
      'fuck', 'shit', 'asshole', 'bitch', 'bastard', 'cunt', 'dick', 'pussy',
      // Arabic Profanity/Swearing
      'شرموط', 'كس', 'منيوك', 'قحبة', 'خول', 'عرص', 'يا ابن ال', 'كلب', 'حمار', 'تفو', 'امك', 'ابوك', 'شاذ',
      // English Politics
      'politics', 'political', 'president', 'government', 'election', 'minister', 'democracy', 'parliament', 'coup', 'revolution',
      // Arabic Politics
      'سياسة', 'سياسي', 'رئيس', 'حكومة', 'انتخابات', 'وزير', 'برلمان', 'انقلاب', 'ديمقراطية', 'حزب', 'أحزاب', 'ثورة', 'شعب',
      // English Military
      'military', 'army', 'soldier', 'weapon', 'war', 'troops', 'battlefield', 'missile', 'combat', 'artillery', 'warfare',
      // Arabic Military
      'جيش', 'عسكري', 'سلاح', 'حرب', 'جنود', 'معركة', 'صاروخ', 'قتال', 'قوات مسلح', 'دفاع', 'كتائب', 'ميليشيا', 'احتلال',
    ];

    final inputLower = sanitized.toLowerCase();
    for (var word in blocklist) {
      if (inputLower.contains(word)) {
        return '[MESSAGE BLOCKED: Message violates communication protocol (Profanity/Politics/Military policy)]';
      }
    }

    return sanitized;
  }

  // Resolve Operator's achievements rank badge from Firestore findings collection
  Future<String> _resolveOperatorRank(String email) async {
    try {
      final snapshot = await _firestore
          .collection('vulnerabilities')
          .where('assignedTo', isEqualTo: email)
          .get();
      
      final count = snapshot.docs.length;
      if (count >= 8) return '🔥 LEGENDARY BREACHER';
      if (count >= 4) return '⚔️ ELITE DISRUPTOR';
      if (count >= 1) return '🛡️ TACTICAL SPECIALIST';
      return '📡 ROOKIE OPERATOR';
    } catch (_) {
      return '📡 ROOKIE OPERATOR';
    }
  }
}
