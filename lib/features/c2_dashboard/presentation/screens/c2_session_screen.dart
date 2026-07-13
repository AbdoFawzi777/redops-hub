import 'package:flutter/material.dart';

class C2SessionScreen extends StatefulWidget {
  const C2SessionScreen({super.key});

  @override
  State<C2SessionScreen> createState() => _C2SessionScreenState();
}

class _C2SessionScreenState extends State<C2SessionScreen> {
  final TextEditingController _commandController = TextEditingController();

  final List<String> _terminalLogs = [
    '[*] Connecting to WIN-DC01 (192.168.1.5)...',
    '[*] Beacon stabilized. Session ID: 3',
    '[+] Meterpreter session 3 opened successfully.',
    'i@WIN-DC01 > whoami',
    'NT AUTHORITY\\SYSTEM',
    'i@WIN-DC01 > ',
  ];

  void _sendCommand() {
    if (_commandController.text.trim().isNotEmpty) {
      setState(() {
        _terminalLogs.add('i@WIN-DC01 > ${_commandController.text}');
        _terminalLogs.add('Executing command on target system...');
        _commandController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF131522);
    const cardColor = Color(0xFF1D2034);
    const primaryColor = Color(0xFFFF5252);
    const terminalGreen = Color(0xFF2ECC71);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Session #3 - WIN-DC01',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.computer_rounded, color: primaryColor, size: 32),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target: WIN-DC01',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'OS: Windows Server 2022 | Arch: x64',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardColor, width: 1.5),
                ),
                child: ListView.builder(
                  itemCount: _terminalLogs.length,
                  itemBuilder: (context, index) {
                    final log = _terminalLogs[index];
                    final isCommand = log.startsWith('i@WIN-DC01 >');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        log,
                        style: TextStyle(
                          color: isCommand ? primaryColor : terminalGreen,
                          fontFamily: 'Courier',
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                    decoration: InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      fillColor: cardColor,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendCommand(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendCommand,
                  icon: const Icon(Icons.send_rounded, color: primaryColor),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(cardColor),
                    padding: WidgetStateProperty.all(const EdgeInsets.all(14)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}