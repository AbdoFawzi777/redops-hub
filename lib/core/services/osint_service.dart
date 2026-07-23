import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OsintSubdomainResult {
  final String name;
  final String issuer;
  final String entryTimestamp;

  OsintSubdomainResult({
    required this.name,
    required this.issuer,
    required this.entryTimestamp,
  });

  factory OsintSubdomainResult.fromJson(Map<String, dynamic> json) {
    return OsintSubdomainResult(
      name: json['name_value'] ?? json['common_name'] ?? 'subdomain',
      issuer: json['issuer_name'] ?? 'Certificate Authority',
      entryTimestamp: json['entry_timestamp'] ?? 'Live',
    );
  }
}

class OsintIpResult {
  final String ip;
  final String country;
  final String city;
  final String isp;
  final String org;
  final String asInfo;
  final List<int> ports;
  final List<String> hostnames;
  final List<String> vulns;

  OsintIpResult({
    required this.ip,
    required this.country,
    required this.city,
    required this.isp,
    required this.org,
    required this.asInfo,
    required this.ports,
    required this.hostnames,
    required this.vulns,
  });
}

class OsintService {
  /// Queries crt.sh Certificate Transparency Database for subdomains
  static Future<List<OsintSubdomainResult>> querySubdomains(String domain) async {
    try {
      final cleanDomain = domain.trim().replaceAll(RegExp(r'https?://'), '').split('/')[0];
      final url = 'https://crt.sh/?q=$cleanDomain&output=json';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final Set<String> seen = {};
        final List<OsintSubdomainResult> results = [];

        for (var item in data) {
          final sub = OsintSubdomainResult.fromJson(Map<String, dynamic>.from(item));
          final cleanName = sub.name.replaceAll('*.', '');
          if (!seen.contains(cleanName)) {
            seen.add(cleanName);
            results.add(sub);
          }
        }
        return results.take(25).toList();
      }
    } catch (e) {
      debugPrint('crt.sh OSINT Error: $e');
    }
    return [];
  }

  /// Queries Shodan InternetDB + IP-API for 100% real live IP OSINT
  static Future<OsintIpResult?> queryIpIntel(String ipAddress) async {
    final cleanIp = ipAddress.trim();
    String country = 'Unknown';
    String city = 'Unknown';
    String isp = 'Unknown ISP';
    String org = 'Unknown Org';
    String asInfo = 'N/A';
    List<int> ports = [];
    List<String> hostnames = [];
    List<String> vulns = [];

    // 1. IP-API Geo & ISP Lookup
    try {
      final ipApiUrl = 'http://ip-api.com/json/$cleanIp?fields=status,country,city,isp,org,as,query';
      final res = await http.get(Uri.parse(ipApiUrl)).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          country = data['country'] ?? 'Unknown';
          city = data['city'] ?? 'Unknown';
          isp = data['isp'] ?? 'Unknown ISP';
          org = data['org'] ?? 'Unknown Org';
          asInfo = data['as'] ?? 'N/A';
        }
      }
    } catch (e) {
      debugPrint('IP-API Error: $e');
    }

    // 2. Shodan InternetDB Port & Vuln Scan
    try {
      final shodanUrl = 'https://internetdb.shodan.io/$cleanIp';
      final res = await http.get(Uri.parse(shodanUrl)).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        ports = data['ports'] != null ? List<int>.from(data['ports']) : [];
        hostnames = data['hostnames'] != null ? List<String>.from(data['hostnames']) : [];
        vulns = data['vulns'] != null ? List<String>.from(data['vulns']) : [];
      }
    } catch (e) {
      debugPrint('Shodan InternetDB Error: $e');
    }

    return OsintIpResult(
      ip: cleanIp,
      country: country,
      city: city,
      isp: isp,
      org: org,
      asInfo: asInfo,
      ports: ports,
      hostnames: hostnames,
      vulns: vulns,
    );
  }
}
