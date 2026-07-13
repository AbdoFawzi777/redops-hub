import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../providers/auth_providers.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isConfirming = false;
  String? _error;

  void _handleContinue() async {
    final pin = _pinController.text;
    final confirm = _confirmController.text;

    if (pin.length != 4) {
      setState(() => _error = 'PIN MUST BE 4 DIGITS');
      return;
    }

    if (!_isConfirming) {
      setState(() {
        _isConfirming = true;
        _error = null;
      });
      return;
    }

    if (pin != confirm) {
      setState(() => _error = 'PINS DO NOT MATCH');
      return;
    }

    await ref.read(authControllerProvider.notifier).setPinCode(pin);
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SECURITY PIN ESTABLISHED')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            RedOpsHeader(
              title: 'PIN CONFIGURATION',
              subtitle: _isConfirming ? 'Confirm your secure access code' : 'Set a 4-digit access code',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.lock_person_outlined, size: 64, color: AppColors.textTertiary),
                    const Gap(32),
                    TextField(
                      controller: _isConfirming ? _confirmController : _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, letterSpacing: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '0000',
                        errorText: _error,
                      ),
                    ),
                    const Gap(40),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        child: Text(_isConfirming ? 'ESTABLISH PROTOCOL' : 'CONTINUE'),
                      ),
                    ),
                    if (_isConfirming) ...[
                      const Gap(12),
                      TextButton(
                        onPressed: () => setState(() {
                          _isConfirming = false;
                          _confirmController.clear();
                        }),
                        child: const Text('BACK TO START'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
