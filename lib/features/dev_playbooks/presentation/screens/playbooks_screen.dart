import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';

class PlaybooksScreen extends ConsumerStatefulWidget {
  const PlaybooksScreen({super.key});

  @override
  ConsumerState<PlaybooksScreen> createState() => _PlaybooksScreenState();
}

class _PlaybooksScreenState extends ConsumerState<PlaybooksScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final _categories = ['ALL', 'WEB', 'ANDROID', 'API', 'AUTH', 'DATABASE'];

  final _playbooks = [
    const _Playbook(
      title: 'SQL Injection Prevention',
      category: 'DATABASE',
      language: 'DART',
      severity: 'CRITICAL',
      description: 'Always use Prepared Statements. Never build SQL queries from raw strings.',
      code: '''// ❌ VULNERABLE — SQL Injection
final query = "SELECT * FROM users WHERE id = \$userId";

// ✅ SECURE — Parameterized Query
final result = await db.rawQuery(
  'SELECT * FROM users WHERE id = ?',
  [userId],
);''',
    ),
    const _Playbook(
      title: 'Broken Authentication Fix',
      category: 'AUTH',
      language: 'DART',
      severity: 'CRITICAL',
      description: 'Use short-lived JWTs with refresh tokens. Never store sensitive credentials in plain text.',
      code: '''// ✅ SECURE Token Validation
Future<bool> validateToken(String token) async {
  try {
    final jwt = JWT.verify(token, SecretKey(secret));
    final exp = jwt.payload['exp'] as int;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 < exp;
  } catch (_) {
    return false;
  }
}''',
    ),
    const _Playbook(
      title: 'XSS Prevention in WebView',
      category: 'WEB',
      language: 'DART',
      severity: 'HIGH',
      description: 'Implement domain whitelisting for WebView content. Sanitize all user inputs before rendering.',
      code: '''// ✅ SECURE Whitelisting
bool isSafeUrl(String url) {
  const allowed = ['yourdomain.com', 'api.yourdomain.com'];
  final uri = Uri.tryParse(url);
  return allowed.contains(uri?.host);
}

if (isSafeUrl(userInput)) {
  controller.loadUrl(userInput);
}''',
    ),
    const _Playbook(
      title: 'Insecure Data Storage Fix',
      category: 'ANDROID',
      language: 'DART',
      severity: 'HIGH',
      description: 'Do not store tokens in SharedPreferences. Use Flutter Secure Storage with encrypted options.',
      code: '''// ✅ SECURE Encrypted Storage
const storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
await storage.write(key: 'token', value: userToken);''',
    ),
  ];

  List<_Playbook> get _filtered {
    return _playbooks.where((p) {
      final matchCat = _selectedCategory == 'ALL' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RedOpsHeader(
              title: s.playbooksTitle,
              subtitle: s.playbooksSubtitle,
            ),
            _buildSearch(isDark, s),
            _buildCategories(isDark),
            Expanded(child: _buildList(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(bool isDark, AppStrings s) {
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

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
          hintText: s.searchPlaybooks,
          prefixIcon: Icon(Icons.search, color: primaryColor, size: 18),
          filled: true,
          fillColor: isDark ? AppColors.bg800 : AppColors.lightSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 2),
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
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(s.noDataFound, style: const TextStyle(color: AppColors.textTertiary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Gap(16),
      itemBuilder: (context, index) => _PlaybookCard(playbook: items[index], index: index),
    );
  }
}

class _PlaybookCard extends ConsumerStatefulWidget {
  const _PlaybookCard({required this.playbook, required this.index});
  final _Playbook playbook;
  final int index;

  @override
  ConsumerState<_PlaybookCard> createState() => _PlaybookCardState();
}

class _PlaybookCardState extends ConsumerState<_PlaybookCard> {
  bool _expanded = false;
  bool _copied = false;

  void _copyCode(AppStrings s) async {
    await Clipboard.setData(ClipboardData(text: widget.playbook.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final p = widget.playbook;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
    final severityColor = p.severity == 'CRITICAL' ? AppColors.criticalFg : AppColors.highFg;

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
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Badge(label: p.severity, color: severityColor),
                            const Gap(8),
                            _Badge(label: p.category, color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary),
                          ],
                        ),
                        const Gap(10),
                        Text(
                          p.title,
                          style: TextStyle(
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
                            fontSize: 15, 
                            fontWeight: FontWeight.w800
                          ),
                        ),
                        const Gap(6),
                        Text(
                          p.description,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, 
                            fontSize: 13, 
                            height: 1.4
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: isDark ? AppColors.border : AppColors.lightBorder),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.language, style: const TextStyle(color: AppColors.textCode, fontSize: 10, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => _copyCode(s),
                        child: Text(
                          _copied ? s.copied.toUpperCase() : s.copyCode, 
                          style: TextStyle(
                            color: _copied ? AppColors.live : primaryColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900
                          )
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : AppColors.lightTextPrimary, 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: AppColors.border)
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        p.code,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textCode, height: 1.6),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

class _Playbook {
  const _Playbook({required this.title, required this.category, required this.language, required this.severity, required this.description, required this.code});
  final String title;
  final String category;
  final String language;
  final String severity;
  final String description;
  final String code;
}
