class ChatMessage {
  final String id;
  final String senderName;
  final String senderEmail;
  final String text;
  final DateTime timestamp;
  final bool isVoice;
  final String? voiceUrl; // Mock URL or base64 data
  final int? voiceDuration; // Duration in seconds
  final String groupId; // Maps to specific private group, e.g. 'lobby'
  final String senderRank; // Operator tag based on vulnerability findings count

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    required this.timestamp,
    required this.isVoice,
    this.voiceUrl,
    this.voiceDuration,
    this.groupId = 'lobby',
    this.senderRank = 'ROOKIE OPERATOR',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isVoice': isVoice,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'groupId': groupId,
      'senderRank': senderRank,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderName: json['senderName'] ?? 'Anonymous',
      senderEmail: json['senderEmail'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isVoice: json['isVoice'] ?? false,
      voiceUrl: json['voiceUrl'],
      voiceDuration: json['voiceDuration'],
      groupId: json['groupId'] ?? 'lobby',
      senderRank: json['senderRank'] ?? 'ROOKIE OPERATOR',
    );
  }
}
