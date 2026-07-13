abstract final class AppConstants {
  static const appName    = 'RedOps Hub';
  static const appVersion = '1.0.0';

  static const boxMeta       = 'redops_meta';
  static const boxVulns      = 'redops_vulns';
  static const boxPayloads   = 'redops_payloads';
  static const boxC2Sessions = 'redops_c2';
  static const boxReports    = 'redops_reports';
  static const boxSettings   = 'redops_settings';

  static const keyUserPin    = 'user_pin_hash';
  static const keyEncryptKey = 'vault_aes_key';
  static const keyC2Token    = 'c2_auth_token';
  static const keyApiBaseUrl = 'api_base_url';

  static const typeIdVulnModel      = 0;
  static const typeIdPayloadModel   = 1;
  static const typeIdC2SessionModel = 2;
  static const typeIdReportModel    = 3;

  static const connectTimeoutSec   = 15;
  static const receiveTimeoutSec   = 30;
  static const wsReconnectDelaySec = 5;
  static const wsMaxRetries        = 10;

  static const severities = ['Critical', 'High', 'Medium', 'Low', 'Info'];

  static const vulnStatuses = [
    'Open', 'In Review', 'Remediated', 'Accepted', 'False Positive',
  ];

  static const payloadCategories = [
    'Web', 'Active Directory', 'Privilege Escalation',
    'Network', 'Post Exploitation', 'Evasion',
  ];

  static const c2Frameworks = [
    'Sliver', 'Havoc', 'Cobalt Strike', 'Metasploit', 'Custom',
  ];
}