import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DevPlaybookItem {
  final String phase;
  final String title;
  final String category;
  final List<String> steps;
  final String command;

  DevPlaybookItem({
    required this.phase,
    required this.title,
    required this.category,
    required this.steps,
    required this.command,
  });

  factory DevPlaybookItem.fromJson(Map<String, dynamic> json) {
    return DevPlaybookItem(
      phase: json['phase'] ?? 'TACTICAL OPS',
      title: json['title'] ?? json['name'] ?? 'Security Playbook',
      category: json['category'] ?? json['type'] ?? 'ALL',
      steps: json['steps'] != null ? List<String>.from(json['steps']) : ['Follow standard operating procedure.'],
      command: json['command'] ?? 'echo "Executing playbook sequence"',
    );
  }
}

class DevPlaybooksService {
  static const String _playbooksApi = 'https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json';

  /// Fetches live developer playbooks dynamically from live CTI source
  static Future<List<DevPlaybookItem>> getLivePlaybooks() async {
    try {
      final response = await http
          .get(Uri.parse(_playbooksApi))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final objects = data['objects'] as List? ?? [];

        final List<DevPlaybookItem> items = [];
        for (var obj in objects.where((o) => o['type'] == 'attack-pattern').take(25)) {
          final String name = obj['name'] ?? 'Tactical Procedure';
          final String phaseName = (obj['kill_chain_phases'] as List?)?.first?['phase_name']?.toString().toUpperCase() ?? 'RECON';
          final String extId = obj['external_references']?.first?['external_id'] ?? 'T1000';
          final String desc = obj['description'] ?? 'Execute tactical operations.';

          String category = 'WEB';
          if (phaseName.contains('CREDENTIAL') || name.toLowerCase().contains('active directory') || name.toLowerCase().contains('domain')) {
            category = 'AD';
          } else if (phaseName.contains('LATERAL') || phaseName.contains('PIVOT')) {
            category = 'PIVOT';
          }

          items.add(DevPlaybookItem(
            phase: 'PHASE - $phaseName ($extId)',
            title: name,
            category: category,
            steps: desc.split('. ').take(3).where((s) => s.trim().isNotEmpty).toList(),
            command: '# MITRE ATT&CK $extId - $name\ncurl -s https://attack.mitre.org/techniques/$extId',
          ));
        }

        if (items.isNotEmpty) return items;
      }
    } catch (e) {
      debugPrint('Live Dev Playbooks Fetch Error: $e');
    }

    return _getFallbackPlaybooks();
  }

  static List<DevPlaybookItem> _getFallbackPlaybooks() {
    return [
      DevPlaybookItem(
        phase: 'PHASE 01 - RECON (T1087)',
        title: 'Active Directory Account Enumeration',
        category: 'AD',
        steps: [
          'Collect domain users and groups via LDAP query',
          'Enumerate privileged accounts and Kerberos SPNs',
        ],
        command: 'SharpHound.exe -c All --domain corp.local',
      ),
      DevPlaybookItem(
        phase: 'PHASE 02 - EXPLOIT (T1558)',
        title: 'Kerberoasting Attack Execution',
        category: 'AD',
        steps: [
          'Request TGS for target SPN account',
          'Perform offline password hash cracking',
        ],
        command: 'Rubeus.exe kerberoast /outfile:hashes.txt',
      ),
      DevPlaybookItem(
        phase: 'PHASE 03 - PIVOT (T1021)',
        title: 'SSH & Chisel Dynamic Tunneling',
        category: 'PIVOT',
        steps: [
          'Setup dynamic SOCKS5 proxy via Chisel server',
          'Pivot internal traffic through encrypted tunnel',
        ],
        command: './chisel server -p 8080 --reverse',
      ),
    ];
  }
}
