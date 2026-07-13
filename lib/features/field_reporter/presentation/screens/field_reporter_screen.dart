import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';

class FieldReporterScreen extends ConsumerStatefulWidget {
  const FieldReporterScreen({super.key});

  @override
  ConsumerState<FieldReporterScreen> createState() => _FieldReporterScreenState();
}

class _FieldReporterScreenState extends ConsumerState<FieldReporterScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      // 1. Check & Request Permissions first
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('MICROPHONE PERMISSION DENIED')),
            );
          }
          return;
        }
      }

      // 2. Initialize Speech
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('Speech Status: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          debugPrint('Speech Error: ${val.errorMsg}');
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SPEECH ERROR: ${val.errorMsg}')),
          );
        },
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _contentController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            RedOpsHeader(
              title: s.reporterTitle,
              subtitle: s.reporterSubtitle,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.border : AppColors.lightBorder, 
                      width: 1
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'REPORT INTEL',
                            style: TextStyle(
                              color: isDark ? AppColors.redPrimary : AppColors.deepBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          // Voice to Text Button
                          GestureDetector(
                            onTap: _listen,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isListening ? AppColors.criticalFg.withValues(alpha: 0.2) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: _isListening ? AppColors.criticalFg : AppColors.textTertiary),
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? AppColors.criticalFg : AppColors.textTertiary,
                                size: 20,
                              ),
                            ).animate(target: _isListening ? 1 : 0)
                             .shimmer(duration: 1.seconds)
                             .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
                          ),
                        ],
                      ),
                      const Gap(20),
                      TextField(
                        controller: _titleController,
                        style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                        decoration: const InputDecoration(
                          labelText: 'REPORT SUBJECT',
                          hintText: 'e.g., Lateral Movement Detected...',
                        ),
                      ),
                      const Gap(20),
                      TextField(
                        controller: _contentController,
                        maxLines: 8,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
                          fontSize: 14, 
                          fontFamily: 'monospace'
                        ),
                        decoration: const InputDecoration(
                          labelText: 'INTELLIGENCE SUMMARY',
                          hintText: 'Press the microphone to speak or type manually...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (_isListening)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'LISTENING... (Confidence: ${(_confidence * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(color: AppColors.lowFg, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const Gap(32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_titleController.text.isEmpty) return;
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('INTEL UPLOADED: ${_titleController.text.toUpperCase()}'),
                                backgroundColor: isDark ? AppColors.redPrimary : AppColors.deepBlue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('TRANSMIT REPORT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
