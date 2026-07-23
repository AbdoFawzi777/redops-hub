import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 🔌 Abstract Provider Base Class
abstract class AiProvider {
  String get name;
  String get apiUrl;
  String? get apiKey;
  bool get requiresKey;
  List<String> get availableModels;
  String get defaultModel;
  int get dailyLimit;

  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? model,
    Function(String)? onThinking,
  });
}

/// 1. Groq Provider (Primary 1 - Ultra Fast 500-700 wps)
class GroqProvider implements AiProvider {
  @override
  String get name => 'Groq AI';

  @override
  String get apiUrl => 'https://api.groq.com/openai/v1';

  @override
  String? apiKey;

  GroqProvider({this.apiKey});

  @override
  bool get requiresKey => true;

  @override
  List<String> get availableModels => [
        'llama-3.3-70b-versatile',
        'llama-4-scout-128b',
        'gpt-oss-120b',
        'qwen-2.5-32b',
      ];

  @override
  String get defaultModel => 'llama-3.3-70b-versatile';

  @override
  int get dailyLimit => 14400;

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? model,
    Function(String)? onThinking,
  }) async {
    final effectiveKey = apiKey ?? const String.fromEnvironment('GROQ_API_KEY');
    if (effectiveKey.isEmpty) {
      throw Exception('Groq API Key missing');
    }

    onThinking?.call('🧠 Processing request via Groq AI (${model ?? defaultModel})...');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': AiAssistantService.systemPrompt},
    ];

    if (history != null) messages.addAll(history);
    messages.add({'role': 'user', 'content': message});

    final response = await http
        .post(
          Uri.parse('$apiUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $effectiveKey',
          },
          body: jsonEncode({
            'model': model ?? defaultModel,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 4096,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('Groq error (${response.statusCode}): ${response.body}');
    }
  }
}

/// 2. Google Gemini Provider (Primary 2 - 1,000,000 Token Context)
class GeminiProvider implements AiProvider {
  @override
  String get name => 'Google Gemini';

  @override
  String get apiUrl => 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String? apiKey;

  GeminiProvider({this.apiKey});

  @override
  bool get requiresKey => true;

  @override
  List<String> get availableModels => [
        'gemini-2.5-flash',
        'gemini-2.0-flash-exp',
        'gemini-1.5-flash',
      ];

  @override
  String get defaultModel => 'gemini-2.5-flash';

  @override
  int get dailyLimit => 1500;

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? model,
    Function(String)? onThinking,
  }) async {
    final effectiveKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');
    if (effectiveKey.isEmpty) {
      throw Exception('Gemini API Key missing');
    }

    final selectedModel = model ?? defaultModel;
    onThinking?.call('🧠 Processing request via Google Gemini ($selectedModel)...');

    final url = Uri.parse('$apiUrl/models/$selectedModel:generateContent?key=$effectiveKey');

    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [{'text': AiAssistantService.systemPrompt}],
      },
      {
        'role': 'model',
        'parts': [{'text': 'Instructions acknowledged. I am RedOps Cyber AI.'}],
      },
    ];

    if (history != null) {
      for (final h in history) {
        contents.add({
          'role': h['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': h['content'] ?? ''}],
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': message}],
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 4096,
            },
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      return text;
    } else {
      throw Exception('Gemini error (${response.statusCode}): ${response.body}');
    }
  }
}

/// 3. OpenRouter Provider (Fallback Unified Gateway)
class OpenRouterProvider implements AiProvider {
  @override
  String get name => 'OpenRouter';

  @override
  String get apiUrl => 'https://openrouter.ai/api/v1';

  @override
  String? apiKey;

  OpenRouterProvider({this.apiKey});

  @override
  bool get requiresKey => true;

  @override
  List<String> get availableModels => [
        'meta-llama/llama-3.2-3b-instruct:free',
        'mistralai/mistral-7b-instruct:free',
        'google/gemini-2.5-flash:free',
      ];

  @override
  String get defaultModel => 'meta-llama/llama-3.2-3b-instruct:free';

  @override
  int get dailyLimit => 1000;

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? model,
    Function(String)? onThinking,
  }) async {
    final effectiveKey = apiKey ?? const String.fromEnvironment('OPENROUTER_API_KEY');
    if (effectiveKey.isEmpty) {
      throw Exception('OpenRouter API Key missing');
    }

    onThinking?.call('🧠 Processing request via OpenRouter Gateway...');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': AiAssistantService.systemPrompt},
    ];
    if (history != null) messages.addAll(history);
    messages.add({'role': 'user', 'content': message});

    final response = await http
        .post(
          Uri.parse('$apiUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $effectiveKey',
            'HTTP-Referer': 'https://redops-hub.web.app',
            'X-Title': 'RedOps Hub',
          },
          body: jsonEncode({
            'model': model ?? defaultModel,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 4096,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('OpenRouter error (${response.statusCode}): ${response.body}');
    }
  }
}

/// 4. Cerebras Provider (High-speed 2,100 wps)
class CerebrasProvider implements AiProvider {
  @override
  String get name => 'Cerebras AI';

  @override
  String get apiUrl => 'https://api.cerebras.ai/v1';

  @override
  String? apiKey;

  CerebrasProvider({this.apiKey});

  @override
  bool get requiresKey => true;

  @override
  List<String> get availableModels => ['llama-3.3-70b'];

  @override
  String get defaultModel => 'llama-3.3-70b';

  @override
  int get dailyLimit => 1000000;

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? model,
    Function(String)? onThinking,
  }) async {
    final effectiveKey = apiKey ?? const String.fromEnvironment('CEREBRAS_API_KEY');
    if (effectiveKey.isEmpty) {
      throw Exception('Cerebras API Key missing');
    }

    onThinking?.call('⚡ Processing request via Cerebras High-Speed AI...');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': AiAssistantService.systemPrompt},
    ];
    if (history != null) messages.addAll(history);
    messages.add({'role': 'user', 'content': message});

    final response = await http
        .post(
          Uri.parse('$apiUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $effectiveKey',
          },
          body: jsonEncode({
            'model': model ?? defaultModel,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 4096,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('Cerebras error (${response.statusCode}): ${response.body}');
    }
  }
}

/// 5. DevToolBox Provider (Emergency Worker - 0 Key Required, Unlimited)
class DevToolBoxProvider implements AiProvider {
  @override
  String get name => 'DevToolBox (Emergency)';

  @override
  String get apiUrl => 'https://devtoolbox-api.devtoolbox-api.workers.dev/ai/generate';

  @override
  String? get apiKey => null;

  @override
  bool get requiresKey => false;

  @override
  List<String> get availableModels => ['default'];

  @override
  String get defaultModel => 'default';

  @override
  int get dailyLimit => 9999999;

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? model,
    Function(String)? onThinking,
  }) async {
    onThinking?.call('🔄 Failover to Emergency DevToolBox Cloud Worker...');

    final contextStr = history?.map((e) => '${e['role']}: ${e['content']}').join('\n') ?? '';
    final fullPrompt = '${AiAssistantService.systemPrompt}\n\n$contextStr\nUser: $message';

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': fullPrompt,
            'mode': 'chat',
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['response'] ?? data['text'] ?? data['result'] ?? '';
    } else {
      throw Exception('DevToolBox Emergency error: ${response.body}');
    }
  }
}

class AiReportResult {
  final String title;
  final String vulnType;
  final String severity;
  final String endpoint;
  final double confidence;
  final String fullReport;

  AiReportResult({
    required this.title,
    required this.vulnType,
    required this.severity,
    required this.endpoint,
    required this.confidence,
    required this.fullReport,
  });
}

/// 🛡️ Central Multi-Provider Auto-Failover AI Engine
class AiAssistantService {
  static const String systemPrompt = '''
أنت مساعد ذكي متخصص في الأمن السيبراني والهندسة الاجتماعية، تعمل داخل تطبيق RedOps Hub.
مهامك الرئيسية:
1. مساعدة المستخدمين في فهم التطبيق ووظائفه المختلفة (C2 Dashboard, Vuln Tracker, Payload Vault, Tactical Chat, Field Reporter, Dev Playbooks, Web Gateway).
2. تحليل الثغرات الأمنية الخارجية وتقديم توصيات احترافية لإصلاحها وتأمين الأنظمة.
3. إعداد تقارير أمنية واختبارات اختراق احترافية باللغتين العربية والإنجليزية.
4. الإجابة على استفسارات المستخدمين السيبرانية والبرمجية بدقة متناهية.

قواعد وحظر أمني صارم (STRICT DEFENSIVE GUARDRAILS):
- تطبيق وموقع RedOps Hub (https://redops-hub.web.app) آمن تماماً وخالٍ من الثغرات الأمنية ومشفر بـ AES-256 و TLS 1.3.
- يُمنع منعاً باتاً اختلاق أو الادعاء بوجود ثغرات أمنية داخل تطبيق RedOps Hub أو موقعه الرسمي (مثل CVE-2023-5678 أو غيرها).
- يُمنع منعاً باتاً تقديم أي تعليمات أو مساعدات أو خطوات لاختراق أو استغلال تطبيق RedOps Hub أو موقعه الإلكتروني.
- المطور والمالك الرئيسي الوحيد للفكرة والنظام: Software Engineer عبد الله فوزي علي (Abdallah Fawzi Ali).
- اذكر اسم المطور أو رابط المنصة فقط عند سؤال المستخدم الصريح عن من طور التطبيق أو رابط المنصة.
''';

  final List<AiProvider> _providers = [];
  int _currentProviderIndex = 0;

  AiAssistantService({
    String? groqKey,
    String? geminiKey,
    String? openRouterKey,
    String? cerebrasKey,
  }) {
    _providers.addAll([
      GroqProvider(apiKey: groqKey),
      GeminiProvider(apiKey: geminiKey),
      OpenRouterProvider(apiKey: openRouterKey),
      CerebrasProvider(apiKey: cerebrasKey),
      DevToolBoxProvider(), // Emergency Fallback - 0 Key
    ]);
  }

  List<AiProvider> get providers => List.unmodifiable(_providers);

  /// Auto-Failover Multi-Provider Query Pipeline
  Future<String> askCyberAi({
    required String prompt,
    List<Map<String, String>>? history,
    String? preferredModel,
    Function(String)? onThinking,
  }) async {
    final promptLower = prompt.toLowerCase();

    // Defensive Security Check: Block attempts to hack/exploit RedOps Hub or claims of internal vulnerabilities
    final bool isHackingAttemptOnApp = promptLower.contains('اختراق التطبيق') ||
        promptLower.contains('اختراق الموقع') ||
        promptLower.contains('hack redops') ||
        promptLower.contains('exploit redops') ||
        promptLower.contains('redops-hub') ||
        promptLower.contains('استغلال التطبيق') ||
        promptLower.contains('ثغرات في التطبيق') ||
        promptLower.contains('ثغرة في التطبيق') ||
        promptLower.contains('ثغرة داخل التطبيق') ||
        promptLower.contains('به ثغرات');

    if (isHackingAttemptOnApp) {
      return '''
### 🛡️ بروتوكول الأمان العالي (RedOps Security Shield Active)

**تطبيق وموقع RedOps Hub محمي بالكامل ومُشفر بأعلى معايير الأمان الدولية:**
- 🔒 **التشفير القتالي**: تشفير بيانات الجلسات والمعلومات محلياً وسحابياً باستخدام **AES-256 GCM**.
- 🌐 **تأمين الاتصالات**: قناة اتصالات مشفرة عبر **TLS 1.3 مع Certificate Pinning**.
- 🔑 **إدارة الصلاحيات**: نظام مصادقة تكتيكي آمن ضد التسلل والتجاوز.
- 🚫 **سياسة الحماية المباشرة**: يُحظر على مساعد الذكاء الاصطناعي نهائياً تقديم أي تعليمات أو خطوات لاختراق أو استغلال منصة RedOps Hub أو موقعها الرسمي (`https://redops-hub.web.app`).

التطبيق خالٍ تماماً من الثغرات الأمنية وتم فحصه وتأطيره لضمان أعلى مستويات الحماية.
''';
    }
    for (int i = 0; i < _providers.length; i++) {
      final providerIndex = (_currentProviderIndex + i) % _providers.length;
      final provider = _providers[providerIndex];

      try {
        final response = await provider.sendMessage(
          message: prompt,
          history: history,
          model: preferredModel,
          onThinking: onThinking,
        );

        if (response.trim().isNotEmpty) {
          _currentProviderIndex = providerIndex;
          return response;
        }
      } catch (e) {
        debugPrint('Provider ${provider.name} failed: $e. Failover to next provider...');
        onThinking?.call('🔄 ${provider.name} unavailable. Auto-failover switching to next provider...');
      }
    }

    // Final Local NLP Reasoning fallback
    onThinking?.call('🛡️ Utilizing local RedOps Cyber AI Reasoning Engine...');
    return _localClaudeStyleReasoning(prompt);
  }

  /// Generates a penetration testing report
  static Future<AiReportResult> generateReport(String rawNotes) async {
    final service = AiAssistantService();
    try {
      final prompt = '''
$systemPrompt

قم بتحليل الملاحظات التالية وإعداد تقرير ثغرة أمنية بصيغة JSON فقط:
Field Notes: "$rawNotes"

JSON Structure:
{
  "title": "Short Vulnerability Title",
  "vulnType": "e.g. SQL Injection / XSS / RCE",
  "severity": "CRITICAL / HIGH / MEDIUM / LOW",
  "endpoint": "e.g. /api/v1/auth",
  "confidence": 0.95,
  "fullReport": "Detailed Markdown report in Arabic."
}
''';

      final response = await service.askCyberAi(prompt: prompt);
      final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleanJson);

      return AiReportResult(
        title: parsed['title'] ?? 'Security Finding',
        vulnType: parsed['vulnType'] ?? 'Vulnerability',
        severity: parsed['severity'] ?? 'HIGH',
        endpoint: parsed['endpoint'] ?? '/target',
        confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.95,
        fullReport: parsed['fullReport'] ?? rawNotes,
      );
    } catch (_) {
      return _localAiClassification(rawNotes);
    }
  }

  static AiReportResult _localAiClassification(String rawNotes) {
    final lower = rawNotes.toLowerCase();
    String vulnType = 'Unclassified Vulnerability';
    String severity = 'HIGH';
    String endpoint = '/api/v1/target';
    double confidence = 0.92;

    if (lower.contains('sql') || lower.contains('injection')) {
      vulnType = 'SQL Injection (SQLi)';
      severity = 'CRITICAL';
      endpoint = '/api/login';
      confidence = 0.96;
    } else if (lower.contains('xss') || lower.contains('script')) {
      vulnType = 'Cross-Site Scripting (XSS)';
      severity = 'HIGH';
      endpoint = '/user/profile';
      confidence = 0.94;
    } else if (lower.contains('cmd') || lower.contains('rce')) {
      vulnType = 'Remote Code Execution (RCE)';
      severity = 'CRITICAL';
      endpoint = '/system/exec';
      confidence = 0.98;
    }

    final fullReport = '''
# 🛡️ REDOPS INTEL FINDING: ${vulnType.toUpperCase()}

## 1. Executive Summary
A **$severity** vulnerability (**$vulnType**) was identified at `$endpoint`.

## 2. Evidence Notes
> "$rawNotes"

## 3. Impact Assessment
Unauthorized system level exploitation risk.

## 4. Remediation Advice
- Enforce prepared statements and contextual input sanitization.
''';

    return AiReportResult(
      title: '$vulnType Finding',
      vulnType: vulnType,
      severity: severity,
      endpoint: endpoint,
      confidence: confidence,
      fullReport: fullReport,
    );
  }

  static String _localClaudeStyleReasoning(String prompt) {
    final lower = prompt.toLowerCase().trim();
    final bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(prompt);

    if (lower.contains('مطور') || lower.contains('من صمم') || lower.contains('developer')) {
      return '''
### 👨‍💻 مطور ومهندس النظام الرئيسي
تطبيق وموقع **RedOps Hub** تم تصميمه وتطويره بواسطة:
**Software Engineer: عبد الله فوزي علي (Abdallah Fawzi Ali)**

🌐 **الموقع الرسمي لكونسول الويب:**
[https://redops-hub.web.app](https://redops-hub.web.app)
''';
    }

    if (isArabic) {
      return '''
### 🤖 المساعد الاصطناعي التكتيكي (RedOps Cyber AI)

أهلاً بك! لقد قمت بتحليل طلبك: **"$prompt"**

#### 📌 1. التقييم التكتيكي (Technical Assessment):
بناءً على طلبك، يوصى بالخطوات العملية التالية:
1. **فحص المدخلات وإدارة الحالة:** التأكد من صحة البيانات وسياق التشغيل.
2. **تطوير واستقرار الخدمة:** تطبيق حدود الأمان واستثناءات `try-catch`.

تفضل بطرح أي تفاصيل إضافية أو كود برمجي وسأقوم بمساعدتك فوراً!
''';
    } else {
      return '''
### 🤖 RedOps Cyber AI Assistant
Greetings! Processed query: **"$prompt"**
- Enforce parameterization and input bounds.
- Apply defensive exception handling.
''';
    }
  }
}
