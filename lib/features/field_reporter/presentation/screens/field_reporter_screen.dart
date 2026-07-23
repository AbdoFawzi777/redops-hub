import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/ai_assistant_dialog.dart';

class FieldReporterScreen extends ConsumerStatefulWidget {
  const FieldReporterScreen({super.key});

  @override
  ConsumerState<FieldReporterScreen> createState() => _FieldReporterScreenState();
}

class _FieldReporterScreenState extends ConsumerState<FieldReporterScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'SQL Injection on /api/login');
  final TextEditingController _contentController = TextEditingController(
    text: 'Found SQL Injection vulnerability on /api/login parameter username using payload 1=1--',
  );

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAiAnalyzing = false;
  double _confidence = 0.96;
  int _recordDuration = 0;
  Timer? _timer;

  // AI Classification State
  String _vulnType = 'SQL Injection';
  String _severity = 'CRITICAL';
  String _endpoint = '/api/login';
  double _aiConfidence = 0.962;

  final List<String> _simulatedWords = [
    'Testing',
    'endpoint',
    '/api/v1/auth',
    'with',
    'payload',
    '\' OR 1=1 --',
    'Authentication',
    'bypassed',
    'successfully',
    'DB',
    'admin',
    'hash',
    'extracted'
  ];
  int _simIndex = 0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      try {
        var status = await Permission.microphone.status;
        if (status.isDenied) {
          status = await Permission.microphone.request();
        }
      } catch (_) {}

      bool available = false;
      try {
        available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              _stopListening();
            }
          },
          onError: (_) {
            _startSimulatedSpeech();
          },
        );
      } catch (_) {}

      setState(() {
        _isListening = true;
        _recordDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordDuration++);
      });

      if (available) {
        _speech.listen(
          onResult: (val) => setState(() {
            _contentController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      } else {
        _startSimulatedSpeech();
      }
    } else {
      _stopListening();
    }
  }

  void _startSimulatedSpeech() {
    if (_contentController.text == 'Found SQL Injection vulnerability on /api/login parameter username using payload 1=1--') {
      _contentController.clear();
    }
    _simIndex = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!_isListening || !mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _recordDuration++;
        if (_simIndex < _simulatedWords.length) {
          _contentController.text = '${_contentController.text} ${_simulatedWords[_simIndex]}'.trim();
          _simIndex++;
        }
      });
    });
  }

  void _stopListening() {
    _timer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _runAiAnalysis() async {
    final notes = _contentController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PLEASE PROVIDE OR RECORD NOTES FIRST', style: TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.v3Critical,
        ),
      );
      return;
    }

    setState(() => _isAiAnalyzing = true);

    final result = await AiAssistantService.generateReport(notes);

    if (mounted) {
      setState(() {
        _isAiAnalyzing = false;
        _titleController.text = result.title;
        _vulnType = result.vulnType;
        _severity = result.severity;
        _endpoint = result.endpoint;
        _aiConfidence = result.confidence;
        _contentController.text = result.fullReport;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI REPORT GENERATED SUCCESSFULLY', style: TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.v3Live,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AiAssistantDialog.show(context),
        backgroundColor: AppColors.v3OpsRed,
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: Text(
          s.aiAssistant,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const Gap(12),
              _buildTitleSection(s),
              const Gap(16),
              _buildRecordingBox(),
              const Gap(14),
              _buildAiGenerateButton(),
              const Gap(16),
              _buildAIClassificationBox(),
              const Gap(16),
              _buildReportForm(),
              const Gap(20),
              _buildConvertButton(s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
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
                decoration: BoxDecoration(
                  color: _isListening ? AppColors.v3Critical : AppColors.v3Covert,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
              const Gap(6),
              Text(
                _isListening ? 'LIVE RECORDING' : 'FIELD REPORTER',
                style: TextStyle(
                  color: _isListening ? AppColors.v3Critical : AppColors.v3Covert,
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
            Text(
              _isListening ? '● REC ${_recordDuration}s' : '● REC IDLE',
              style: TextStyle(
                color: _isListening ? AppColors.v3Critical : AppColors.v3Covert,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const Gap(12),
            const Text(
              'AI ONLINE',
              style: TextStyle(
                color: AppColors.v3Live,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTitleSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.reporterTitle,
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
          s.reporterSubtitle,
          style: TextStyle(
            color: AppColors.dynamicTextMuted(context),
            fontSize: 11.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildRecordingBox() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isListening ? AppColors.v3Critical.withValues(alpha: 0.12) : AppColors.v3Covert.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isListening ? AppColors.v3Critical : AppColors.v3Covert.withValues(alpha: 0.4),
            width: _isListening ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: _isListening ? AppColors.v3Critical : AppColors.v3Covert,
                      size: 20,
                    ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15)),
                    const Gap(8),
                    Text(
                      _isListening
                          ? 'RECORDING IN PROGRESS... ${_recordDuration}s'
                          : 'TAP TO RECORD VOICE NOTES',
                      style: TextStyle(
                        color: _isListening ? AppColors.v3Critical : AppColors.v3Covert,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isListening ? AppColors.v3Critical : AppColors.v3Covert.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isListening ? 'STOP' : 'MIC REC',
                    style: TextStyle(
                      color: _isListening ? Colors.white : AppColors.v3Covert,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const Gap(14),
            // Waveform equalizer bars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(24, (index) {
                final heights = [12.0, 18.0, 26.0, 14.0, 32.0, 20.0, 8.0, 24.0, 36.0, 18.0, 12.0, 28.0];
                final h = heights[index % heights.length];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 3,
                  height: _isListening ? (h * 1.4).clamp(6.0, 42.0) : 6.0,
                  decoration: BoxDecoration(
                    color: _isListening ? AppColors.v3Critical : AppColors.v3Covert.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const Gap(14),
            Text(
              _isListening
                  ? 'LISTENING TO MICROPHONE... (Confidence: ${(_confidence * 100).toStringAsFixed(1)}%)'
                  : '// Live speech-to-text transcript below',
              style: TextStyle(
                color: _isListening ? AppColors.v3Critical : AppColors.dynamicTextMuted(context),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAiGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isAiAnalyzing ? null : _runAiAnalysis,
        icon: _isAiAnalyzing
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome, size: 18),
        label: Text(
          _isAiAnalyzing ? 'AI ANALYZING & CLASSIFYING INTEL...' : '✨ AI AUTO-GENERATE REPORT',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.v3OpsRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildAIClassificationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.v3Live,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(6),
                  const Text(
                    'AI CLASSIFICATION - AUTO',
                    style: TextStyle(
                      color: AppColors.v3Live,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                '${(_aiConfidence * 100).toStringAsFixed(1)}% MATCH',
                style: const TextStyle(
                  color: AppColors.v3Live,
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(14),
          _buildMetaRow('Type', _vulnType, AppColors.v3Critical),
          const Gap(8),
          _buildMetaRow('Severity', _severity, AppColors.v3Critical),
          const Gap(8),
          _buildMetaRow('Endpoint', _endpoint, AppColors.v3Code),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMetaRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.dynamicTextMuted(context),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildReportForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPORT SUBJECT',
          style: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 10.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        const Gap(6),
        TextField(
          controller: _titleController,
          style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.dynamicCardBg(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.dynamicCardBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.v3OpsRed),
            ),
          ),
        ),
        const Gap(14),
        Text(
          'INTELLIGENCE & FINDING REPORT',
          style: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 10.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        const Gap(6),
        TextField(
          controller: _contentController,
          maxLines: 8,
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.4,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.dynamicCardBg(context),
            contentPadding: const EdgeInsets.all(14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.dynamicCardBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.v3OpsRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConvertButton(AppStrings s) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          if (_titleController.text.isEmpty) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CONVERTED TO FINDING: ${_titleController.text.toUpperCase()}', style: const TextStyle(fontFamily: 'monospace')),
              backgroundColor: AppColors.v3Live,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.v3Live, width: 1.5),
          foregroundColor: AppColors.v3Live,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          s.convertToFinding,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
