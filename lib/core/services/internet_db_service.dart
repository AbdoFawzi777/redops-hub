import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InternetDbResult {
  final String ip;
  final List<int> ports;
  final List<String> cpes;
  final List<String> hostnames;
  final List<String> tags;
  final List<String> vulns;

  InternetDbResult({
    required this.ip,
    required this.ports,
    required this.cpes,
    required this.hostnames,
    required this.tags,
    required this.vulns,
  });

  factory InternetDbResult.fromJson(Map<String, dynamic> json) {
    return InternetDbResult(
      ip: json['ip'] ?? '',
      ports: List<int>.from(json['ports'] ?? []),
      cpes: List<String>.from(json['cpes'] ?? []),
      hostnames: List<String>.from(json['hostnames'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      vulns: List<String>.from(json['vulns'] ?? []),
    );
  }
}

class InternetDbService {
  /// Queries Shodan InternetDB for passive IP reconnaissance (No API Key Required)
  static Future<InternetDbResult?> scanIp(String ip) async {
    final cleanIp = ip.trim();
    if (cleanIp.isEmpty) return null;

    try {
      final url = Uri.parse('https://internetdb.shodan.io/$cleanIp');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return InternetDbResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Shodan InternetDB Query Error: $e');
    }
    return null;
  }
}
