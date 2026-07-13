import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../domain/entities/vulnerability.dart';
import '../providers/vuln_providers.dart';

class VulnCreateScreen extends ConsumerStatefulWidget {
  const VulnCreateScreen({super.key});

  @override
  ConsumerState<VulnCreateScreen> createState() => _VulnCreateScreenState();
}

class _VulnCreateScreenState extends ConsumerState<VulnCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _projectController = TextEditingController(text: 'Operation Nightfall');
  final _cveController = TextEditingController();
  
  // Form State
  VulnSeverity _severity = VulnSeverity.medium;
  VulnStatus _status = VulnStatus.open;
  VulnType _type = VulnType.vulnerability;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _projectController.dispose();
    _cveController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final newVuln = Vulnerability(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      severity: _severity,
      status: _status,
      type: _type,
      projectName: _projectController.text.trim(),
      cveId: _cveController.text.isNotEmpty ? _cveController.text.trim() : null,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(createVulnUseCaseProvider).call(newVuln);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('INTEL LOGGED SUCCESSFULLY'),
            backgroundColor: AppColors.live,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TRANSMISSION ERROR: $e'),
            backgroundColor: AppColors.criticalFg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedOpsHeader(
              title: s.newFinding,
              subtitle: 'Tactical intelligence documentation',
              showBackButton: true,
              showSettingsButton: false,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle('OPERATIONAL DETAILS'),
                    const Gap(16),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                      decoration: const InputDecoration(
                        labelText: 'FINDING TITLE',
                        hintText: 'e.g., Unauthenticated RCE in Web Portal',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                    ),
                    const Gap(20),

                    // Project & CVE
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _projectController,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                            decoration: const InputDecoration(labelText: 'PROJECT'),
                            validator: (v) => v == null || v.isEmpty ? 'Project required' : null,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: _cveController,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontFamily: 'monospace'),
                            decoration: const InputDecoration(labelText: 'CVE ID (OPTIONAL)', hintText: 'CVE-2024-XXXX'),
                          ),
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Description
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                      decoration: const InputDecoration(
                        labelText: 'TECHNICAL DESCRIPTION',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                    ),
                    const Gap(24),

                    _buildSectionTitle('CLASSIFICATION'),
                    const Gap(16),

                    // Severity Selector
                    _buildDropdown<VulnSeverity>(
                      label: 'SEVERITY LEVEL',
                      value: _severity,
                      items: VulnSeverity.values.map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.label.toUpperCase(), style: TextStyle(color: _getSeverityColor(v), fontWeight: FontWeight.bold)),
                      )).toList(),
                      onChanged: (v) => setState(() => _severity = v!),
                    ),
                    const Gap(20),

                    Row(
                      children: [
                        // Status Selector
                        Expanded(
                          child: _buildDropdown<VulnStatus>(
                            label: 'STATUS',
                            value: _status,
                            items: VulnStatus.values.map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.label.toUpperCase()),
                            )).toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                        const Gap(12),
                        // Type Selector
                        Expanded(
                          child: _buildDropdown<VulnType>(
                            label: 'ENTRY TYPE',
                            value: _type,
                            items: VulnType.values.map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.label.toUpperCase()),
                            )).toList(),
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ),
                      ],
                    ),
                    
                    const Gap(40),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.terminal_rounded),
                            Gap(12),
                            Text('TRANSMIT TO VAULT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                    const Gap(20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
        const Gap(6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.bg800,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(VulnSeverity s) => switch (s) {
    VulnSeverity.critical => AppColors.criticalFg,
    VulnSeverity.high => AppColors.highFg,
    VulnSeverity.medium => AppColors.mediumFg,
    VulnSeverity.low => AppColors.lowFg,
    VulnSeverity.info => AppColors.infoFg,
  };
}
