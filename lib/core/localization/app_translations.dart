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
  
  // Vuln Stats
  String get total;
  String get critical;
  String get open;
  String get fixed;
  String get searchHint;
  String get newFinding;
  
  // Vault & Playbooks
  String get searchVault;
  String get searchPlaybooks;
  String get noDataFound;
  String get copyPayload;
  String get copyCode;

  // Common
  String get back;
  String get copy;
  String get copied;
}

class EnglishStrings extends AppStrings {
  @override String get appName => 'RedOps Hub';
  @override String get c2Title => 'COMMAND & CONTROL';
  @override String get c2Subtitle => 'Active agents & remote session monitoring';
  @override String get vulnsTitle => 'VULN TRACKER';
  @override String get vulnsSubtitle => 'Live Security Intel · Operation Nightfall';
  @override String get reporterTitle => 'FIELD REPORTER';
  @override String get reporterSubtitle => 'Submit intelligence reports to command';
  @override String get vaultTitle => 'PAYLOAD VAULT';
  @override String get vaultSubtitle => 'Encrypted tactical exploit repository';
  @override String get playbooksTitle => 'DEV PLAYBOOKS';
  @override String get playbooksSubtitle => 'Tactical remediation guides';
  @override String get settingsTitle => 'SYSTEM SETTINGS';
  @override String get settingsSubtitle => 'Configure operational environment';

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
  @override String get searchHint => 'SCAN CVE, TITLE, TAGS...';
  @override String get newFinding => 'NEW FINDING';
  
  @override String get searchVault => 'SEARCH VAULT...';
  @override String get searchPlaybooks => 'SEARCH REMEDIATION GUIDES...';
  @override String get noDataFound => 'NO INTEL MATCHES SEARCH CRITERIA';
  @override String get copyPayload => 'COPY PAYLOAD';
  @override String get copyCode => 'COPY CODE';

  @override String get back => 'BACK';
  @override String get copy => 'COPY';
  @override String get copied => 'COPIED';
}

class ArabicStrings extends AppStrings {
  @override String get appName => 'ريد أوبس هب';
  @override String get c2Title => 'مركز القيادة والسيطرة';
  @override String get c2Subtitle => 'مراقبة الوكلاء النشطين والجلسات عن بعد';
  @override String get vulnsTitle => 'متتبع الثغرات';
  @override String get vulnsSubtitle => 'استخبارات أمنية مباشرة · عملية نايت فول';
  @override String get reporterTitle => 'المراسل الميداني';
  @override String get reporterSubtitle => 'إرسال تقارير الاستخبارات إلى القيادة';
  @override String get vaultTitle => 'مخزن الأكواد';
  @override String get vaultSubtitle => 'مستودع تكتيكي مشفر للأكواد الهجومية';
  @override String get playbooksTitle => 'أدلة المعالجة';
  @override String get playbooksSubtitle => 'أدلة تكتيكية لفرق الهندسة والبرمجة';
  @override String get settingsTitle => 'إعدادات النظام';
  @override String get settingsSubtitle => 'تكوين بيئة العمليات والتفضيلات';

  @override String get appearance => 'المظهر';
  @override String get themeMode => 'ثيم النظام';
  @override String get localization => 'اللغة والمنطقة';
  @override String get language => 'لغة العمليات';
  @override String get security => 'الأمان';
  @override String get biometric => 'المصادقة البيومترية';
  @override String get terminateSession => 'إنهاء الجلسة';

  @override String get total => 'الإجمالي';
  @override String get critical => 'حرج جداً';
  @override String get open => 'مفتوح';
  @override String get fixed => 'تم الإصلاح';
  @override String get searchHint => 'ابحث عن CVE، عنوان، أو وسوم...';
  @override String get newFinding => 'إضافة اكتشاف';

  @override String get searchVault => 'البحث في المخزن...';
  @override String get searchPlaybooks => 'البحث في أدلة المعالجة...';
  @override String get noDataFound => 'لم يتم العثور على استخبارات تطابق البحث';
  @override String get copyPayload => 'نسخ الكود الهجومي';
  @override String get copyCode => 'نسخ الكود البرمجي';

  @override String get back => 'رجوع';
  @override String get copy => 'نسخ';
  @override String get copied => 'تم النسخ';
}
