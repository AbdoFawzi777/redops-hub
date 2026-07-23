import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

final l10nProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(languageProvider);
  return locale.languageCode == 'ar' ? ArabicStrings() : EnglishStrings();
});

abstract class AppStrings {
  String get appName;
  String get c2Title;
  String get c2Subtitle;
  String get vulnsTitle;
  String get vulnsSubtitle;
  String get reporterTitle;
  String get reporterSubtitle;
  String get vaultTitle;
  String get vaultSubtitle;
  String get playbooksTitle;
  String get playbooksSubtitle;
  String get settingsTitle;
  String get settingsSubtitle;
  
  // Settings
  String get appearance;
  String get themeMode;
  String get localization;
  String get language;
  String get security;
  String get biometric;
  String get terminateSession;
  
  // Vuln Stats & Search
  String get total;
  String get critical;
  String get open;
  String get fixed;
  String get searchHint;
  String get newFinding;
  
  // Vault & Playbooks & AI
  String get searchVault;
  String get searchPlaybooks;
  String get noDataFound;
  String get copyPayload;
  String get copyCode;
  String get aiAssistant;
  String get convertToFinding;

  // Common
  String get back;
  String get copy;
  String get copied;
}

class EnglishStrings extends AppStrings {
  @override String get appName => 'RedOps Hub';
  @override String get c2Title => 'Command & Control';
  @override String get c2Subtitle => '// real-time agent monitoring';
  @override String get vulnsTitle => 'Threat Intelligence';
  @override String get vulnsSubtitle => '// live findings feed';
  @override String get reporterTitle => 'Voice Intel';
  @override String get reporterSubtitle => '// AI-assisted field notes & speech-to-text';
  @override String get vaultTitle => 'Tactical Arsenal';
  @override String get vaultSubtitle => '// encrypted payload library';
  @override String get playbooksTitle => 'Attack Strategies';
  @override String get playbooksSubtitle => '// red team operation guides';
  @override String get settingsTitle => 'Control Center';
  @override String get settingsSubtitle => '// operator profile & security protocols';

  @override String get appearance => 'APPEARANCE';
  @override String get themeMode => 'System Theme';
  @override String get localization => 'LOCALIZATION';
  @override String get language => 'Operational Language';
  @override String get security => 'SECURITY';
  @override String get biometric => 'Biometric Authentication';
  @override String get terminateSession => 'TERMINATE SESSION';

  @override String get total => 'TOTAL';
  @override String get critical => 'CRITICAL';
  @override String get open => 'OPEN';
  @override String get fixed => 'FIXED';
  @override String get searchHint => 'SCAN CVE, TITLE, TARGET...';
  @override String get newFinding => 'NEW FINDING';
  
  @override String get searchVault => 'SEARCH PAYLOADS...';
  @override String get searchPlaybooks => 'SEARCH REMEDIATION GUIDES...';
  @override String get noDataFound => 'NO INTEL MATCHES SEARCH CRITERIA';
  @override String get copyPayload => 'COPY PAYLOAD';
  @override String get copyCode => 'COPY CODE';
  @override String get aiAssistant => 'AI ASSISTANT';
  @override String get convertToFinding => '→ CONVERT TO FINDING';

  @override String get back => 'BACK';
  @override String get copy => 'COPY';
  @override String get copied => 'COPIED';
}

class ArabicStrings extends AppStrings {
  @override String get appName => 'ريد أوبس هب';
  @override String get c2Title => 'القيادة والسيطرة';
  @override String get c2Subtitle => '// مراقبة الوكلاء والمنارات المباشرة';
  @override String get vulnsTitle => 'استخبارات التهديدات';
  @override String get vulnsSubtitle => '// تغذية الثغرات المكتشفة لحظياً';
  @override String get reporterTitle => 'المراسل الصوتي';
  @override String get reporterSubtitle => '// ملاحظات تكتيكية وتحويل الصوت لنص بالذكاء الاصطناعي';
  @override String get vaultTitle => 'مخزن الأكواد الهجومية';
  @override String get vaultSubtitle => '// مكتبة الأكواد والتكتيكات المشفرة';
  @override String get playbooksTitle => 'استراتيجيات الهجوم';
  @override String get playbooksSubtitle => '// أدلة عمليات فرق Red Team';
  @override String get settingsTitle => 'مركز التحكم والضبط';
  @override String get settingsSubtitle => '// بروفايل المشغل وبروتوكولات الأمان';

  @override String get appearance => 'المظهر والنظام';
  @override String get themeMode => 'ثيم التطبيق (فاتح / داكن)';
  @override String get localization => 'اللغة والمنطقة';
  @override String get language => 'لغة التطبيق والعمليات';
  @override String get security => 'بروتوكولات الأمان';
  @override String get biometric => 'البصمة وبصمة الوجه';
  @override String get terminateSession => 'إنهاء الجلسة التكتيكية';

  @override String get total => 'الإجمالي';
  @override String get critical => 'حرج جداً';
  @override String get open => 'مفتوح';
  @override String get fixed => 'تم الإصلاح';
  @override String get searchHint => 'بحث عن CVE، عنوان، أو مستهدف...';
  @override String get newFinding => 'إضافة ثغرة';

  @override String get searchVault => 'البحث في مخزن الحمولات...';
  @override String get searchPlaybooks => 'البحث في أدلة الهجوم المعالجة...';
  @override String get noDataFound => 'لم يتم العثور على بيانات تطابق البحث';
  @override String get copyPayload => 'نسخ الكود الهجومي';
  @override String get copyCode => 'نسخ الكود البرمجي';
  @override String get aiAssistant => 'المساعد الذكي';
  @override String get convertToFinding => '← تحويل إلى ثغرة رسمية';

  @override String get back => 'رجوع';
  @override String get copy => 'نسخ';
  @override String get copied => 'تم النسخ';
}
