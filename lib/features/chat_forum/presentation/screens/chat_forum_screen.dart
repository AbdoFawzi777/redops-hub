import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';

class ChatForumScreen extends ConsumerStatefulWidget {
  const ChatForumScreen({super.key});

  @override
  ConsumerState<ChatForumScreen> createState() => _ChatForumScreenState();
}

class _ChatForumScreenState extends ConsumerState<ChatForumScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordSeconds++);
      if (_recordSeconds >= 60) {
        _stopAndSendRecording();
      }
    });
  }

  void _stopAndSendRecording() {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final duration = _recordSeconds == 0 ? 1 : _recordSeconds;
    setState(() => _isRecording = false);
    
    // Send simulated voice note URL
    ref.read(chatControllerProvider.notifier).sendVoiceMessage(
      'mock_voice_note_${DateTime.now().millisecondsSinceEpoch}.aac',
      duration,
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(chatControllerProvider.notifier).sendTextMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(chatMessagesStreamProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final myEmail = auth?.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const RedOpsHeader(
              title: 'TACTICAL FORUM',
              subtitle: 'Secure operator exchange channel',
              showBackButton: true,
            ),
            // Network Warning / Security Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.criticalFg.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(Icons.gpp_maybe_outlined, color: AppColors.criticalFg, size: 16),
                  Gap(8),
                  Expanded(
                    child: Text(
                      'SECURE CHANNEL: File uploads and active exploit script exchanges are blocked.',
                      style: TextStyle(color: AppColors.criticalFg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 48, color: isDark ? AppColors.border : AppColors.lightBorder),
                          const Gap(12),
                          const Text('NO MESSAGES YET', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold, fontSize: 13)),
                          const Gap(4),
                          const Text('Start the conversation with the team.', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const Gap(16),
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderEmail == myEmail;
                      return _MessageBubble(message: msg, isMe: isMe);
                    },
                  );
                },
                loading: () => const Center(child: TacticalLoader(size: 100)),
                error: (err, _) => Center(
                  child: Text('FAILED TO CONNECT: $err', style: const TextStyle(color: AppColors.criticalFg, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          // Voice recording gesture detector
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopAndSendRecording(),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.criticalFg.withValues(alpha: 0.2) : (isDark ? AppColors.bg800 : AppColors.lightScaffold),
                shape: BoxShape.circle,
                border: Border.all(color: _isRecording ? AppColors.criticalFg : Colors.transparent),
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none_outlined,
                color: _isRecording ? AppColors.criticalFg : primaryColor,
                size: 22,
              ),
            ),
          ).animate(target: _isRecording ? 1 : 0).shake(hz: 3, duration: 1.seconds),
          const Gap(12),
          Expanded(
            child: _isRecording
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.criticalFg.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.criticalFg, shape: BoxShape.circle),
                        ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).fadeOut(duration: 500.ms),
                        const Gap(8),
                        Text(
                          'RECORDING VOICE NOTE: ${_recordSeconds}s',
                          style: const TextStyle(color: AppColors.criticalFg, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  )
                : TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter secure message...',
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: isDark ? AppColors.bg800 : AppColors.lightScaffold,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
          ),
          const Gap(12),
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: primaryColor,
              onPressed: _sendMessage,
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.senderName,
                style: TextStyle(color: isMe ? primaryColor : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const Gap(6),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 8),
              ),
            ],
          ),
          const Gap(4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe 
                  ? primaryColor.withValues(alpha: 0.15) 
                  : (isDark ? AppColors.bg800 : AppColors.lightScaffold),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
              ),
              border: Border.all(
                color: isMe ? primaryColor : (isDark ? AppColors.border : AppColors.lightBorder),
                width: 1,
              ),
            ),
            child: message.isVoice ? _buildVoicePlayer(isDark, primaryColor) : _buildTextBody(isDark, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBody(bool isDark, Color primaryColor) {
    final isSecurityNotice = message.text.contains('SECURITY NOTICE');
    return Text(
      message.text,
      style: TextStyle(
        color: isSecurityNotice 
            ? AppColors.criticalFg 
            : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
        fontSize: 13,
        fontWeight: isSecurityNotice ? FontWeight.bold : FontWeight.normal,
        fontFamily: isSecurityNotice ? 'monospace' : null,
      ),
    );
  }

  Widget _buildVoicePlayer(bool isDark, Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow_rounded, color: primaryColor, size: 24),
        const Gap(8),
        // Visual soundwave simulation
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(10, (index) {
            final h = (index % 3 + 1) * 4.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2,
              height: h,
              color: primaryColor.withValues(alpha: 0.6),
            );
          }),
        ),
        const Gap(10),
        Text(
          '${message.voiceDuration}s',
          style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
