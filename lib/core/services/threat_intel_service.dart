import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class ThreatUrlItem {
  final String id;
  final String url;
  final String urlStatus;
  final String threatType;
  final String dateAdded;

  ThreatUrlItem({
    required this.id,
    required this.url,
    required this.urlStatus,
    required this.threatType,
    required this.dateAdded,
  });

  factory ThreatUrlItem.fromJson(Map<String, dynamic> json) {
    return ThreatUrlItem(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? json['ioc'] ?? '',
      urlStatus: json['url_status'] ?? json['ioc_status'] ?? 'online',
      threatType: json['threat'] ?? json['threat_type'] ?? 'malware_download',
      dateAdded: json['date_added'] ?? json['first_seen'] ?? '',
    );
  }
}

class ThreatIntelService {
  static final ThreatIntelService _instance = ThreatIntelService._internal();
  factory ThreatIntelService() => _instance;
  ThreatIntelService._internal();

  static const String _urlhausApi = 'https://urlhaus-api.abuse.ch/v1/urls/recent/';
  static const String _threatFoxApi = 'https://threatfox-api.abuse.ch/api/v1/';
  static const String _mitreCtiUrl = 'https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json';

  Box? _cacheBox;

  /// Service initialization
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen('threat_cache')) {
        _cacheBox = await Hive.openBox('threat_cache');
      } else {
        _cacheBox = Hive.box('threat_cache');
      }
    } catch (e) {
      debugPrint('ThreatIntelService init error: $e');
    }
  }

  /// Fetches live threats with multi-tier auto-failover
  Future<List<Map<String, dynamic>>> getLiveThreats() async {
    List<Map<String, dynamic>> threats = [];

    // 1. Try URLhaus
    try {
      threats = await _fetchFromUrlhaus();
      if (threats.isNotEmpty) {
        await _cacheThreats('urlhaus', threats);
        return threats;
      }
    } catch (e) {
      debugPrint('⚠️ URLhaus API Failed: $e');
    }

    // 2. Try ThreatFox
    try {
      threats = await _fetchFromThreatFox();
      if (threats.isNotEmpty) {
        await _cacheThreats('threatfox', threats);
        return threats;
      }
    } catch (e) {
      debugPrint('⚠️ ThreatFox API Failed: $e');
    }

    // 3. Try MITRE CTI (Backup)
    try {
      threats = await _fetchFromMitreCti();
      if (threats.isNotEmpty) {
        await _cacheThreats('mitre', threats);
        return threats;
      }
    } catch (e) {
      debugPrint('⚠️ MITRE CTI Failed: $e');
    }

    // 4. Try Local Cache
    final cached = _getCachedThreats();
    if (cached.isNotEmpty) {
      debugPrint('🔄 Using locally cached threats data.');
      return cached;
    }

    // 5. Default Fallback
    return _getDefaultThreats();
  }

  Future<List<Map<String, dynamic>>> _fetchFromUrlhaus() async {
    try {
      final response = await http.get(
        Uri.parse(_urlhausApi),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['query_status'] == 'ok' || data['urls'] != null) {
          final List urls = data['urls'] ?? [];
          return urls.map((e) => Map<String, dynamic>.from(e)).toList().take(30).toList();
        }
      }

      if (response.statusCode == 401) {
        debugPrint('⚠️ URLhaus Unauthorized (401) - Failing over to backup providers...');
        return [];
      }
    } catch (e) {
      debugPrint('⚠️ URLhaus API Error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchFromThreatFox() async {
    try {
      final response = await http.post(
        Uri.parse(_threatFoxApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': 'get_iocs',
          'days': 1,
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['query_status'] == 'ok' && data['data'] != null) {
          final List iocs = data['data'] ?? [];
          return iocs.map((e) => Map<String, dynamic>.from(e)).toList().take(30).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ ThreatFox API Error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchFromMitreCti() async {
    try {
      final response = await http.get(
        Uri.parse(_mitreCtiUrl),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final objects = data['objects'] as List? ?? [];

        return objects
            .where((obj) => obj['type'] == 'attack-pattern')
            .map((obj) => {
                  'id': obj['external_references']?.first?['external_id'] ?? obj['id'] ?? '',
                  'name': obj['name'] ?? '',
                  'description': obj['description'] ?? '',
                  'source': 'MITRE ATT&CK',
                  'severity': 'HIGH',
                })
            .toList()
            .take(20)
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ MITRE CTI Error: $e');
    }
    return [];
  }

  Future<void> _cacheThreats(String source, List<Map<String, dynamic>> threats) async {
    if (_cacheBox == null) return;
    try {
      await _cacheBox!.put('latest_threats', {
        'data': threats,
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
      });
    } catch (e) {
      debugPrint('Error caching threats: $e');
    }
  }

  List<Map<String, dynamic>> _getCachedThreats() {
    if (_cacheBox == null) return [];
    try {
      final cached = _cacheBox!.get('latest_threats');
      if (cached != null) {
        final timestamp = DateTime.parse(cached['timestamp']);
        final age = DateTime.now().difference(timestamp);

        if (age.inHours < 24) {
          return List<Map<String, dynamic>>.from(cached['data']);
        }
      }
    } catch (e) {
      debugPrint('Error reading cached threats: $e');
    }
    return [];
  }

  List<Map<String, dynamic>> _getDefaultThreats() {
    return [
      {
        'id': 'default-1',
        'name': 'العمل في وضع Offline التكتيكي',
        'description': 'تعذر جلب التهديدات الحية. يرجى التحقق من اتصال الشبكة.',
        'source': 'Local Fallback',
        'severity': 'MEDIUM',
      },
    ];
  }

  /// Legacy helper method compatibility
  static Future<List<ThreatUrlItem>> getRecentMaliciousUrls() async {
    final service = ThreatIntelService();
    final items = await service.getLiveThreats();
    return items.map((e) => ThreatUrlItem.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>?> getMitreAttackMatrix() async {
    try {
      final response = await http
          .get(Uri.parse(_mitreCtiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('MITRE CTI Fetch Error: $e');
    }
    return null;
  }
}
