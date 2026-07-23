import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../core/services/ai_assistant_service.dart';
import '../../core/theme/app_colors.dart';

class AiAssistantDialog extends StatefulWidget {
  const AiAssistantDialog({super.key, this.initialPrompt});

  final String? initialPrompt;

  static void show(BuildContext context, {String? initialPrompt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiAssistantDialog(initialPrompt: initialPrompt),
    );
  }

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends State<AiAssistantDialog> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late final AiAssistantService _aiService;

  bool _isLoading = false;
  String _thinkingStatus = '🧠 RedOps Multi-AI Engine Initializing...';
  String _activeProviderName = 'Auto-Failover AI';

  String _groqKey = '';
  String _geminiKey = '';
  String _openRouterKey = '';
  String _cerebrasKey = '';

  @override
  void initState() {
    super.initState();
    _aiService = AiAssistantService(
      groqKey: _groqKey,
      geminiKey: _geminiKey,
      openRouterKey: _openRouterKey,
      cerebrasKey: _cerebrasKey,
    );

    _messages.add(
      _ChatMessage(
        text: '👋 أهلاً بك يا مشغل! أنا **RedOps Cyber AI**.\nنظام الذكاء الاصطناعي متعدد المزودين المزود بخاصية التبديل التلقائي (**Auto-Failover** بين Groq, Gemini, OpenRouter, Cerebras, DevToolBox Emergency).\n\nكيف يمكنني مساعدتك في عملياتك اليوم؟',
        isAi: true,
      ),
    );

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      _sendQuery();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
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

  Future<void> _sendQuery() async {
    final query = _promptController.text.trim();
    if (query.isEmpty || _isLoading) return;

    _promptController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: query, isAi: false));
      _isLoading = true;
      _thinkingStatus = '🧠 Connecting to AI Provider Pipeline...';
    });
    _scrollToBottom();

    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {'role': m.isAi ? 'assistant' : 'user', 'content': m.text})
        .toList();

    final response = await _aiService.askCyberAi(
      prompt: query,
      history: history,
      onThinking: (status) {
        if (mounted) {
          setState(() {
            _thinkingStatus = status;
            if (status.contains('Groq')) _activeProviderName = 'Groq AI';
            if (status.contains('Gemini')) _activeProviderName = 'Google Gemini';
            if (status.contains('OpenRouter')) _activeProviderName = 'OpenRouter';
            if (status.contains('Cerebras')) _activeProviderName = 'Cerebras AI';
            if (status.contains('DevToolBox')) _activeProviderName = 'DevToolBox (Emergency)';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(text: response, isAi: true, providerLabel: _activeProviderName));
      });
      _scrollToBottom();
    }
  }

  void _showApiKeysConfigDialog() {
    final groqCtrl = TextEditingController(text: _groqKey);
    final geminiCtrl = TextEditingController(text: _geminiKey);
    final openRouterCtrl = TextEditingController(text: _openRouterKey);
    final cerebrasCtrl = TextEditingController(text: _cerebrasKey);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCardBg(context),
          title: Text('🔑 AI PROVIDER API KEYS CONFIG', style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildKeyField(groqCtrl, 'Groq API Key (gsk_...)'),
                const Gap(8),
                _buildKeyField(geminiCtrl, 'Google Gemini Key (AIzaSy...)'),
                const Gap(8),
                _buildKeyField(openRouterCtrl, 'OpenRouter Key (sk-or-...)'),
                const Gap(8),
                _buildKeyField(cerebrasCtrl, 'Cerebras Key (cs_...)'),
                const Gap(10),
                Text(
                  '💡 If keys are omitted, the system will automatically failover to free DevToolBox Emergency Worker (Unlimited, 0 Key required).',
                  style: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 10, fontFamily: 'monospace'),
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
                setState(() {
                  _groqKey = groqCtrl.text.trim();
                  _geminiKey = geminiCtrl.text.trim();
                  _openRouterKey = openRouterCtrl.text.trim();
                  _cerebrasKey = cerebrasCtrl.text.trim();
                  _aiService = AiAssistantService(
                    groqKey: _groqKey,
                    geminiKey: _geminiKey,
                    openRouterKey: _openRouterKey,
                    cerebrasKey: _cerebrasKey,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('SAVE & APPLY', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKeyField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 11),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 10.5, fontFamily: 'monospace'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: AppColors.dynamicOuterBg(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.dynamicBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: AppColors.v3OpsRed, width: 1.5)),
        ),
        child: Column(
          children: [
            // Drag Handle & Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dynamicOuterBg(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.dynamicCardBorder(context))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.v3OpsRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.v3OpsRed, size: 18),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RedOps Cyber AI (Auto-Failover Engine)',
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: AppColors.v3Live, shape: BoxShape.circle),
                            ),
                            const Gap(4),
                            Text(
                              'Active Provider: $_activeProviderName',
                              style: const TextStyle(
                                color: AppColors.v3Covert,
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.vpn_key_outlined, color: AppColors.v3OpsRed, size: 18),
                    onPressed: _showApiKeysConfigDialog,
                    tooltip: 'Configure API Keys',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.dynamicTextMuted(context), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Chat Message Stream
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildBubble(msg);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.v3OpsRed,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5)),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        _thinkingStatus,
                        style: const TextStyle(
                          color: AppColors.v3OpsRed,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Input Box - Always stays above keyboard
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.dynamicOuterBg(context),
                border: Border(top: BorderSide(color: AppColors.dynamicCardBorder(context))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        onSubmitted: (_) => _sendQuery(),
                        style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ask RedOps Cyber AI anything...',
                          hintStyle: TextStyle(color: AppColors.dynamicTextMuted(context), fontFamily: 'monospace', fontSize: 11.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    const Gap(10),
                    GestureDetector(
                      onTap: _sendQuery,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.v3OpsRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: msg.isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (msg.isAi && msg.providerLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                '// ${msg.providerLabel}',
                style: const TextStyle(color: AppColors.v3Covert, fontSize: 9.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 310),
            decoration: BoxDecoration(
              color: msg.isAi ? AppColors.dynamicCardBg(context) : AppColors.v3OpsRed.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: msg.isAi ? AppColors.dynamicCardBorder(context) : AppColors.v3OpsRed,
                width: 1,
              ),
            ),
            child: SelectableText(
              msg.text,
              style: TextStyle(
                color: msg.isAi ? AppColors.dynamicTextPrimary(context) : Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isAi;
  final String? providerLabel;

  _ChatMessage({required this.text, required this.isAi, this.providerLabel});
}
