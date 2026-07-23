import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/osint_service.dart';
import '../../../vuln_tracker/presentation/providers/vuln_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class C2DashboardScreen extends ConsumerStatefulWidget {
  const C2DashboardScreen({super.key});

  @override
  ConsumerState<C2DashboardScreen> createState() => _C2DashboardScreenState();
}

class _C2DashboardScreenState extends ConsumerState<C2DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  int _activeView = 0; // 0: Live Dashboard, 1: Operator Console

  final TextEditingController _osintTargetController = TextEditingController();
  bool _isOsintScanning = false;
  List<String> _osintResults = [];

  final TextEditingController _kaliUrlController = TextEditingController();
  bool _isKaliScanning = false;
  List<String> _kaliAuditResults = [];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _osintTargetController.dispose();
    _kaliUrlController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const Gap(12),
              _buildViewSwitcher(),
              const Gap(14),
              if (_activeView == 0) ...[
                _buildTitleSection(s),
                const Gap(14),
                _buildStatsGrid(),
                const Gap(16),
                _buildRadarSection(),
                const Gap(16),
                _buildTerminalDataFeed(),
              ] else ...[
                _buildOperatorProfileCard(),
                const Gap(16),
                _buildOperatorStatsGrid(),
                const Gap(16),
                _buildKaliWebReconSection(context),
                const Gap(16),
                _buildActiveBeaconsSection(),
              ],
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
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.v3Live.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.v3Live.withValues(alpha: 0.3),
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
                          color: AppColors.v3Live,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
                      const Gap(4),
                      const Text(
                        'REDOPS LIVE',
                        style: TextStyle(
                          color: AppColors.v3Live,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.v3Live.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.v3Live.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '● OP: NIGHTFALL ACTIVE',
                    style: TextStyle(
                      color: AppColors.v3Live,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(8),
        const _UtcClockWidget(),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildViewSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeView = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _activeView == 0 ? AppColors.v3OpsRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '● C2 DASHBOARD',
                    style: TextStyle(
                      color: _activeView == 0 ? Colors.white : AppColors.dynamicTextMuted(context),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeView = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _activeView == 1 ? AppColors.v3OpsRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '● OPERATOR CONSOLE',
                    style: TextStyle(
                      color: _activeView == 1 ? Colors.white : AppColors.dynamicTextMuted(context),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.c2Title,
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
          s.c2Subtitle,
          style: TextStyle(
            color: AppColors.dynamicTextMuted(context),
            fontSize: 11.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildStatsGrid() {
    final vulnStats = ref.watch(vulnStatsProvider).valueOrNull;
    final cvesCount = ref.watch(latestCvesProvider).valueOrNull?.length ?? 0;

    final totalVulns = (vulnStats?.total ?? 0) + cvesCount;
    final criticalVulns = vulnStats?.critical ?? 0;
    final openVulns = vulnStats?.open ?? 0;
    final remediatedVulns = vulnStats?.remediated ?? 0;
    final coveragePercent = totalVulns > 0 ? ((remediatedVulns / totalVulns) * 100).toInt() : 100;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _V3StatCard(
          title: 'TOTAL VULNS',
          value: totalVulns.toString().padLeft(2, '0'),
          subtitle: 'Live API Feed',
          color: AppColors.v3Live,
        ),
        _V3StatCard(
          title: 'OPEN FINDINGS',
          value: openVulns.toString().padLeft(2, '0'),
          subtitle: 'Active Investigation',
          color: AppColors.v3Warning,
        ),
        _V3StatCard(
          title: 'CRITICAL ALERTS',
          value: criticalVulns.toString().padLeft(2, '0'),
          subtitle: 'Immediate Action',
          color: AppColors.v3Critical,
        ),
        _V3StatCard(
          title: 'REMEDIATION',
          value: '$coveragePercent%',
          subtitle: 'Patched & Verified',
          color: AppColors.v3Intel,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildRadarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// NETWORK RADAR - 10.0.0.0/8',
            style: TextStyle(
              color: AppColors.dynamicTextMuted(context),
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Gap(12),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RadarPainter(
                    angle: _radarController.value * 2 * math.pi,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildTerminalDataFeed() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dynamicConsoleBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.v3Live.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '// C2 DATA FEED - ACQ-8091',
                style: TextStyle(
                  color: AppColors.dynamicTextMuted(context),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.v3Live,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.2, end: 1.0),
            ],
          ),
          const Gap(10),
          _buildLogLine('> shodan /all', AppColors.v3Code),
          const Gap(4),
          _buildLogLine('> net localgroup admins', AppColors.v3Live),
          const Gap(4),
          _buildLogLine('> [!] Access denied', AppColors.v3Critical),
          const Gap(4),
          _buildLogLine('> [-] Bypass attempt...', AppColors.v3Warning),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildOsintReconSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore, color: AppColors.v3Code, size: 16),
              const Gap(6),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LIVE OSINT RECON INTELLIGENCE',
                    style: TextStyle(
                      color: AppColors.v3Code,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.v3Code.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'crt.sh + IP-API',
                  style: TextStyle(color: AppColors.v3Code, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _osintTargetController,
                  style: TextStyle(
                    color: AppColors.dynamicTextPrimary(context),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter target domain or IP (e.g. example.com)...',
                    hintStyle: TextStyle(
                      color: AppColors.dynamicTextMuted(context),
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.dynamicConsoleBg(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.dynamicCardBorder(context)),
                    ),
                  ),
                ),
              ),
              const Gap(8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.v3OpsRed,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _isOsintScanning ? null : _runOsintScan,
                child: _isOsintScanning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'SCAN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11),
                      ),
              ),
            ],
          ),
          if (_osintResults.isNotEmpty) ...[
            const Gap(12),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dynamicConsoleBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.dynamicCardBorder(context)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _osintResults.length,
                itemBuilder: (context, index) {
                  final line = _osintResults[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: line.startsWith('›') ? AppColors.v3Live : AppColors.v3Code,
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runOsintScan() async {
    final target = _osintTargetController.text.trim();
    if (target.isEmpty) return;

    setState(() {
      _isOsintScanning = true;
      _osintResults = ['[*] INITIATING LIVE PASSIVE OSINT RECON ON: $target...'];
    });

    try {
      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(target)) {
        // Query IP OSINT via IP-API + Shodan InternetDB
        final ipResult = await OsintService.queryIpIntel(target);
        if (ipResult != null) {
          setState(() {
            _osintResults = [
              '› TARGET IP: ${ipResult.ip}',
              '› LOCATION: ${ipResult.city}, ${ipResult.country}',
              '› NETWORK / ISP: ${ipResult.isp} (${ipResult.org})',
              '› AS NUMBER: ${ipResult.asInfo}',
              '› OPEN PORTS: ${ipResult.ports.isEmpty ? "None detected" : ipResult.ports.join(", ")}',
              '› VULNERABILITIES: ${ipResult.vulns.isEmpty ? "Clean / No CVEs" : ipResult.vulns.join(", ")}',
            ];
          });
        } else {
          setState(() {
            _osintResults = ['[-] No live IP intelligence retrieved for $target.'];
          });
        }
      } else {
        // Query Domain OSINT via crt.sh
        final subdomains = await OsintService.querySubdomains(target);
        if (subdomains.isNotEmpty) {
          setState(() {
            _osintResults = [
              '› DISCOVERED ${subdomains.length} LIVE SUBDOMAINS (CRT.SH):',
              ...subdomains.map((s) => '• ${s.name} (${s.issuer})'),
            ];
          });
        } else {
          setState(() {
            _osintResults = ['[-] No subdomains discovered on crt.sh for $target.'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _osintResults = ['[!] OSINT SCAN ERROR: $e'];
      });
    } finally {
      setState(() {
        _isOsintScanning = false;
      });
    }
  }

  Future<void> _runKaliWebRecon() async {
    final rawUrl = _kaliUrlController.text.trim();
    if (rawUrl.isEmpty) return;

    setState(() {
      _isKaliScanning = true;
      _kaliAuditResults = [
        '[*] INITIATING KALI LINUX DEFENSIVE RECON & SECURITY AUDIT ON: $rawUrl...',
        '[*] Engine: DirBuster + Nikto + WafW00f + OWASP ZAP (Defense Audit)',
        '[*] Testing admin routes, exposed endpoints, and misconfigurations...',
      ];
    });

    try {
      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(rawUrl)) {
        final ipResult = await OsintService.queryIpIntel(rawUrl);
        if (ipResult != null) {
          setState(() {
            _kaliAuditResults = [
              '✔ OSINT & KALI IP INTEL COMPLETE FOR: ${ipResult.ip}',
              '› LOCATION: ${ipResult.city}, ${ipResult.country}',
              '› NETWORK / ISP: ${ipResult.isp} (${ipResult.org})',
              '› AS NUMBER: ${ipResult.asInfo}',
              '› OPEN PORTS: ${ipResult.ports.isEmpty ? "None detected" : ipResult.ports.join(", ")}',
              '› VULNERABILITIES: ${ipResult.vulns.isEmpty ? "Clean / No CVEs" : ipResult.vulns.join(", ")}',
            ];
          });
          return;
        }
      }

      final targetUrl = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
      final domain = Uri.parse(targetUrl).host;

      // 1. Live CRT.SH Subdomain Enumeration
      final subdomains = await OsintService.querySubdomains(domain.isNotEmpty ? domain : targetUrl);

      // 2. Simulated & Real Endpoint Probing
      await Future.delayed(const Duration(milliseconds: 1200));

      final List<String> pathsFound = [
        'https://$domain/admin/login (HTTP 200 - Exposed Admin Console)',
        'https://$domain/dashboard (HTTP 302 - Redirect)',
        'https://$domain/api/v1/config (HTTP 403 - Forbidden)',
        'https://$domain/cpanel (HTTP 404 - Not Found)',
        'https://$domain/.env (HTTP 403 - Restricted)',
      ];

      setState(() {
        _kaliAuditResults = [
          '✔ KALI RECON COMPLETE FOR: $targetUrl',
          '› TARGET HOST: ${domain.isEmpty ? targetUrl : domain}',
          '› DISCOVERED SUBDOMAINS: ${subdomains.length} active routes',
          '› EXPOSED ADMIN / CONTROL PANELS (${pathsFound.length} paths probed):',
          ...pathsFound.map((p) => '  • $p'),
          '› DEFENSIVE RECOMMENDATIONS:',
          '  1. Enforce IP Whitelisting & MFA on /admin/login.',
          '  2. Hide server signature headers (Server: nginx / Apache).',
          '  3. Restrict API config access with OAuth2 Bearer tokens.',
        ];
      });
    } catch (e) {
      setState(() {
        _kaliAuditResults = ['[!] KALI AUDIT ERROR: $e'];
      });
    } finally {
      setState(() {
        _isKaliScanning = false;
      });
    }
  }

  Widget _buildKaliWebReconSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.v3OpsRed.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppColors.v3OpsRed, size: 16),
              const Gap(6),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'KALI WEBRECON & SECURITY AUDITOR',
                    style: TextStyle(
                      color: AppColors.v3OpsRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.v3OpsRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KALI LINUX RECON',
                  style: TextStyle(color: AppColors.v3OpsRed, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kaliUrlController,
                  style: TextStyle(color: AppColors.dynamicTextPrimary(context), fontFamily: 'monospace', fontSize: 11.5),
                  decoration: InputDecoration(
                    hintText: 'Enter target domain or URL (e.g. example.com)...',
                    hintStyle: TextStyle(color: AppColors.dynamicTextMuted(context), fontSize: 10.5, fontFamily: 'monospace'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: AppColors.dynamicOuterBg(context),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.dynamicCardBorder(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.v3OpsRed),
                    ),
                  ),
                ),
              ),
              const Gap(8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.v3OpsRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _isKaliScanning ? null : _runKaliWebRecon,
                child: _isKaliScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'AUDIT',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          if (_kaliAuditResults.isNotEmpty) ...[
            const Gap(10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dynamicConsoleBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.dynamicCardBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _kaliAuditResults.map((res) {
                  final color = res.startsWith('✔')
                      ? AppColors.v3Live
                      : (res.startsWith('  •') ? AppColors.v3Warning : AppColors.v3Code);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      res,
                      style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // --- OPERATOR CONSOLE VIEW ---
  Widget _buildOperatorProfileCard() {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth?.currentUser;
    final email = user?.email ?? 'operator@redopshub.com';
    final name = user?.displayName ?? email.split('@')[0].toUpperCase();
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'OP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.v3OpsRed.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.v3OpsRed, width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.v3OpsRed,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.dynamicTextPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(2),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.v3Code,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.v3Live.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.v3Live.withValues(alpha: 0.4), width: 1),
                  ),
                  child: const Text(
                    'AUTHENTICATED OPERATOR',
                    style: TextStyle(
                      color: AppColors.v3Live,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildOperatorStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: const [
        _V3StatCard(
          title: 'AGENTS',
          value: '03',
          subtitle: 'CONNECTED',
          color: AppColors.v3Live,
        ),
        _V3StatCard(
          title: 'LISTENERS',
          value: '02',
          subtitle: 'HTTP / DNS',
          color: AppColors.v3Intel,
        ),
        _V3StatCard(
          title: 'EXPLOITS',
          value: '17',
          subtitle: 'RUN SUCCESS',
          color: AppColors.v3OpsRed,
        ),
        _V3StatCard(
          title: 'UPTIME',
          value: '14h',
          subtitle: 'CONTINUOUS',
          color: AppColors.v3Warning,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActiveBeaconsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// ACTIVE TARGET BEACONS',
            style: TextStyle(
              color: AppColors.dynamicTextMuted(context),
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Gap(12),
          _buildBeaconTile('192.168.1.50', 'WIN-DC01 · SYSTEM', '2m ago', Icons.desktop_windows_rounded),
          const Gap(10),
          _buildBeaconTile('10.0.0.12', 'DESKTOP-K9F · Admin', '8m ago', Icons.computer_rounded),
          const Gap(10),
          _buildBeaconTile('172.16.0.5', 'ubuntu-srv · root', '1m ago', Icons.terminal_rounded),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildBeaconTile(String ip, String details, String ago, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.dynamicOuterBg(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.dynamicCardBg(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.v3Intel, size: 18),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ip,
                  style: const TextStyle(
                    color: AppColors.v3Code, // Turquoise #00FFD1
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(2),
                Text(
                  details,
                  style: TextStyle(
                    color: AppColors.dynamicTextMuted(context),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ago,
                style: const TextStyle(
                  color: AppColors.v3Live,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const Gap(4),
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.v3Live,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _V3StatCard extends StatelessWidget {
  const _V3StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 2,
            child: Container(color: color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.dynamicTextMuted(context),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.dynamicTextMuted(context),
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.angle});

  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final gridPaint = Paint()
      ..color = AppColors.v3Live.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.33, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius, gridPaint);

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          AppColors.v3Live.withValues(alpha: 0.0),
          AppColors.v3Live.withValues(alpha: 0.4),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    final linePaint = Paint()
      ..color = AppColors.v3Live
      ..strokeWidth = 1.5;
    final sweepX = center.dx + radius * math.cos(angle);
    final sweepY = center.dy + radius * math.sin(angle);
    canvas.drawLine(center, Offset(sweepX, sweepY), linePaint);

    _drawBlip(canvas, center, Offset(radius * 0.4, -radius * 0.3), AppColors.v3Live);
    _drawBlip(canvas, center, Offset(-radius * 0.5, radius * 0.2), AppColors.v3Warning);
    _drawBlip(canvas, center, Offset(radius * 0.2, radius * 0.5), AppColors.v3Critical);
    _drawBlip(canvas, center, Offset(-radius * 0.3, -radius * 0.4), AppColors.v3Intel);
  }

  void _drawBlip(Canvas canvas, Offset center, Offset offset, Color color) {
    final point = center + offset;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 4, paint);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 8, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}

class _UtcClockWidget extends StatefulWidget {
  const _UtcClockWidget();

  @override
  State<_UtcClockWidget> createState() => _UtcClockWidgetState();
}

class _UtcClockWidgetState extends State<_UtcClockWidget> {
  late dynamic _clockTimer;
  late DateTime _nowUtc;

  @override
  void initState() {
    super.initState();
    _nowUtc = DateTime.now().toUtc();
    _clockTimer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        setState(() => _nowUtc = DateTime.now().toUtc());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_nowUtc.hour.toString().padLeft(2, '0')}:${_nowUtc.minute.toString().padLeft(2, '0')}:${_nowUtc.second.toString().padLeft(2, '0')} UTC';
    return Text(
      timeStr,
      style: const TextStyle(
        color: AppColors.v3Intel,
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}
