import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tactical_notification_service.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_group.dart';
import '../providers/chat_providers.dart';

class ChatForumScreen extends ConsumerStatefulWidget {
  const ChatForumScreen({super.key});

  @override
  ConsumerState<ChatForumScreen> createState() => _ChatForumScreenState();
}

class _ChatForumScreenState extends ConsumerState<ChatForumScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speechToText;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  bool _isPaused = false;

  Future<void> _toggleOrStartRecording() async {
    if (_isRecording) {
      _stopAndSendRecording();
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for WhatsApp Voice Notes!'),
            backgroundColor: AppColors.v3Critical,
          ),
        );
      }
      return;
    }

    bool available = await _speechToText.initialize(
      onStatus: (status) => debugPrint('STT STATUS: $status'),
      onError: (errorNotification) => debugPrint('STT ERROR: $errorNotification'),
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordSeconds = 0;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() => _recordSeconds++);
      }
    });

    if (available) {
      _speechToText.listen(
        onResult: (result) {
          if (mounted && result.recognizedWords.isNotEmpty) {
            _messageController.text = result.recognizedWords;
            setState(() {});
          }
        },
      );
    }
  }

  void _togglePauseResumeRecording() {
    if (!_isRecording) return;
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _speechToText.stop();
    } else {
      _speechToText.listen(
        onResult: (result) {
          if (mounted && result.recognizedWords.isNotEmpty) {
            _messageController.text = result.recognizedWords;
            setState(() {});
          }
        },
      );
    }
  }

  void _cancelRecording() {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _speechToText.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordSeconds = 0;
    });
  }

  void _stopAndSendRecording() {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _speechToText.stop();

    final duration = _recordSeconds == 0 ? 1 : _recordSeconds;
    final text = _messageController.text.trim();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendTextMessage(text);
      _messageController.clear();
    } else {
      ref.read(chatControllerProvider.notifier).sendVoiceMessage(
        'voice_note_${DateTime.now().millisecondsSinceEpoch}.aac',
        duration,
      );
    }

    TacticalNotificationService.playNotificationTone(NotificationToneType.chatMessage);
  }

  void _sendMessage() {
    if (_isRecording) {
      _stopAndSendRecording();
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(chatControllerProvider.notifier).sendTextMessage(text);
    TacticalNotificationService.playNotificationTone(NotificationToneType.chatMessage);
  }

  void _showGroupSelector(BuildContext context, List<ChatGroup> groups, String activeGroupId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dynamicCardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.dynamicCardBorder(context), borderRadius: BorderRadius.circular(2)),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'CHAT ROOMS',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1, color: AppColors.dynamicTextPrimary(context)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.group_add_outlined),
                    color: AppColors.v3OpsRed,
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateGroupDialog(context);
                    },
                    tooltip: 'Create Group',
                  ),
                ],
              ),
              Divider(color: AppColors.dynamicCardBorder(context)),
              Expanded(
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isActive = group.id == activeGroupId;
                    return ListTile(
                      onTap: () {
                        ref.read(currentGroupIdProvider.notifier).state = group.id;
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        group.id == 'lobby' ? Icons.public : Icons.group_work_outlined,
                        color: isActive ? AppColors.v3OpsRed : AppColors.dynamicTextMuted(context),
                      ),
                      title: Text(
                        group.name,
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(context),
                          fontFamily: 'monospace',
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        group.description,
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.dynamicTextMuted(context)),
                      ),
                      trailing: isActive ? const Icon(Icons.check_circle_outline, color: AppColors.v3OpsRed) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final membersController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCardBg(context),
          title: Text('CREATE PRIVATE GROUP', style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 14)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace'),
                  decoration: const InputDecoration(labelText: 'Group Name', hintText: 'e.g. RedTeam-01'),
                ),
                const Gap(12),
                TextField(
                  controller: descController,
                  style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace'),
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Private briefing lounge'),
                ),
                const Gap(12),
                TextField(
                  controller: membersController,
                  style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Invite Members (Emails)',
                    hintText: 'user1@email.com, user2@email.com',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: AppColors.dynamicTextMuted(context), fontFamily: 'monospace')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.v3OpsRed, foregroundColor: Colors.white),
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                final membersStr = membersController.text.trim();
                if (name.isEmpty) return;

                final List<String> members = membersStr.isNotEmpty
                    ? membersStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                    : [];

                ref.read(chatControllerProvider.notifier).createNewGroup(name, desc, members);
                Navigator.pop(context);
              },
              child: const Text('CREATE', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider);
    final groupsAsync = ref.watch(chatGroupsStreamProvider);
    final activeGroupId = ref.watch(currentGroupIdProvider);

    final auth = ref.watch(firebaseAuthProvider);
    final myEmail = auth?.currentUser?.email ?? '';

    final activeGroup = groupsAsync.maybeWhen(
      data: (groups) => groups.firstWhere((g) => g.id == activeGroupId,
          orElse: () => ChatGroup(id: 'lobby', name: 'Public Lobby', description: 'Global operator lounge.', ownerEmail: '', members: [])),
      orElse: () => ChatGroup(id: 'lobby', name: 'Public Lobby', description: 'Global operator lounge.', ownerEmail: '', members: []),
    );

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(activeGroup, groupsAsync, activeGroupId),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Gap(8),
                            _buildTitleSection(activeGroup),
                            const Gap(10),
                            _buildModerationBanner(),
                            const Gap(12),
                            if (messages.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.forum_outlined, size: 48, color: AppColors.dynamicTextMuted(context)),
                                      const Gap(12),
                                      Text('SECURE ROOM INITIALIZED', style: TextStyle(color: AppColors.dynamicTextMuted(context), fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)),
                                      const Gap(4),
                                      Text('All messages are protected with TLS/SSL tunnel.', style: TextStyle(color: AppColors.dynamicTextMuted(context), fontFamily: 'monospace', fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                      final msg = messages[index];
                      final isMe = msg.senderEmail == myEmail;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          onLongPress: () => _showMessageOptionsModal(context, msg),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: TacticalLoader(size: 100)),
                error: (err, _) => Center(
                  child: Text('FAILED TO CONNECT: $err', style: const TextStyle(color: AppColors.v3Critical, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(ChatGroup activeGroup, AsyncValue<List<ChatGroup>> groupsAsync, String activeGroupId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.v3Covert.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.v3Covert.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.v3Covert,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
                const Gap(6),
                const Text(
                  'TACTICAL CHAT - SECURE',
                  style: TextStyle(
                    color: AppColors.v3Covert,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              groupsAsync.maybeWhen(
                data: (groups) => IconButton(
                  icon: Icon(Icons.switch_left, color: AppColors.dynamicTextMuted(context), size: 20),
                  onPressed: () => _showGroupSelector(context, groups, activeGroupId),
                  tooltip: 'Switch Room',
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const Text(
                'ENCRYPTED',
                style: TextStyle(
                  color: AppColors.v3Intel,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTitleSection(ChatGroup activeGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activeGroup.name,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
        const Gap(2),
        Text(
          '// ${activeGroup.description}',
          style: TextStyle(
            color: AppColors.dynamicTextMuted(context),
            fontSize: 11.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildModerationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.v3Critical.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.v3Critical.withValues(alpha: 0.4), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.gpp_maybe_outlined, color: AppColors.v3Critical, size: 16),
          Gap(8),
          Expanded(
            child: Text(
              'No classified intel in plaintext. TLS tunnel active. Ops only.',
              style: TextStyle(
                color: AppColors.v3Critical,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dynamicOuterBg(context),
        border: Border(top: BorderSide(color: AppColors.dynamicCardBorder(context), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _isRecording
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.v3Critical.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.v3Critical.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isPaused ? AppColors.v3Warning : AppColors.v3Critical,
                              shape: BoxShape.circle,
                            ),
                          ).animate(target: _isPaused ? 0 : 1, onPlay: (c) => c.repeat()).fade(begin: 0.2, end: 1.0),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              _isPaused ? 'PAUSED: ${_recordSeconds}s' : 'RECORDING: ${_recordSeconds}s',
                              style: TextStyle(
                                color: _isPaused ? AppColors.v3Warning : AppColors.v3Critical,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _togglePauseResumeRecording,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isPaused ? AppColors.v3Warning.withValues(alpha: 0.2) : AppColors.v3Critical.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: _isPaused ? AppColors.v3Warning : AppColors.v3Critical,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: _messageController,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Type tactical message...',
                        hintStyle: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 12, fontFamily: 'monospace'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.dynamicCardBg(context),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.dynamicCardBorder(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.v3OpsRed),
                        ),
                      ),
                    ),
            ),
            const Gap(8),
            // Dedicated Voice Mic Button (WhatsApp Style: Tap or Long Press)
            GestureDetector(
              onTap: _toggleOrStartRecording,
              onLongPressStart: (_) => _toggleOrStartRecording(),
              onLongPressEnd: (_) => _stopAndSendRecording(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.v3Critical : AppColors.v3Covert.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _isRecording ? AppColors.v3Critical : AppColors.v3Covert),
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic_rounded,
                  color: _isRecording ? Colors.white : AppColors.v3Covert,
                  size: 18,
                ),
              ),
            ),
            const Gap(6),
            // Dedicated Send Button (Always Visible & Active)
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.v3OpsRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptionsModal(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dynamicCardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.dynamicCardBorder(context), borderRadius: BorderRadius.circular(2)),
              ),
              const Gap(12),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.v3Code),
                title: const Text('📋 Copy Message', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard!'), backgroundColor: AppColors.v3Live),
                  );
                },
              ),
              if (!message.isVoice)
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded, color: AppColors.v3Warning),
                  title: const Text('✏️ Edit Message', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.v3Critical),
                title: const Text('🗑️ Delete Message', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.v3Critical)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(chatControllerProvider.notifier).deleteMessage(message.id);
                  TacticalNotificationService.playNotificationTone(NotificationToneType.medLowVuln);
                },
              ),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ChatMessage message) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCardBg(context),
          title: const Text('✏️ EDIT MESSAGE', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editController,
            style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.dynamicOuterBg(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(fontFamily: 'monospace')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.v3OpsRed, foregroundColor: Colors.white),
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  await ref.read(chatControllerProvider.notifier).editMessage(message.id, newText);
                }
                Navigator.pop(context);
              },
              child: const Text('SAVE', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe, this.onLongPress});
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(
                  color: isMe ? AppColors.v3OpsRed : AppColors.v3Code,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const Gap(6),
              Text(
                '${DateFormat('HH:mm').format(message.timestamp)} UTC',
                style: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 8.5, fontFamily: 'monospace'),
              ),
            ],
          ),
          const Gap(4),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.v3OpsRed.withValues(alpha: 0.9)
                    : AppColors.dynamicCardBg(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                ),
                border: Border.all(
                  color: isMe ? AppColors.v3OpsRed : AppColors.dynamicCardBorder(context),
                  width: 1,
                ),
              ),
              child: message.isVoice ? _buildVoicePlayer() : _buildTextBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBody(BuildContext context) {
    return Text(
      message.text,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.dynamicTextPrimary(context),
        fontSize: 12.5,
        fontFamily: 'monospace',
        height: 1.35,
      ),
    );
  }

  Widget _buildVoicePlayer() {
    return _InteractiveVoicePlayer(duration: message.voiceDuration ?? 3);
  }
}

class _InteractiveVoicePlayer extends StatefulWidget {
  const _InteractiveVoicePlayer({required this.duration});
  final int duration;

  @override
  State<_InteractiveVoicePlayer> createState() => _InteractiveVoicePlayerState();
}

class _InteractiveVoicePlayerState extends State<_InteractiveVoicePlayer> {
  bool _isPlaying = false;
  int _currentSeconds = 0;
  Timer? _playbackTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/chat_ping.wav'));
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _currentSeconds = 0;
        });
      }
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (mounted) {
          if (_currentSeconds >= widget.duration) {
            timer.cancel();
            await _audioPlayer.stop();
            setState(() {
              _isPlaying = false;
              _currentSeconds = 0;
            });
          } else {
            setState(() => _currentSeconds++);
            await _audioPlayer.stop();
            await _audioPlayer.play(AssetSource('sounds/chat_ping.wav'));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _togglePlay,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            const Gap(6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(10, (index) {
                final active = _isPlaying && (index < ((_currentSeconds / widget.duration) * 10));
                final h = ((index % 4) + 1) * 3.5 + 4.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 2.5,
                  height: active ? h + 4 : h,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white60,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const Gap(8),
            Text(
              _isPlaying ? '${widget.duration - _currentSeconds}s' : '${widget.duration}s',
              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
