abstract final class AppRoutes {
  static const splash     = '/';
  static const login      = '/login';
  static const biometrics = '/biometrics';
  static const c2         = '/c2';
  static const vulns      = '/vulns';
  static const vulnCreate = '/vulns/create';
  static const vulnDetail = '/vulns/:vulnId';
  static String vulnDetailPath(String id) => '/vulns/$id';
  static const reporter   = '/reporter';
  static const vault      = '/vault';
  static const playbooks  = '/playbooks';
  static const settings   = '/settings';
  static const profile    = '/settings/profile';
  static const pinSetup   = '/settings/pin-setup';
  static const pinGate    = '/pin-gate';
  static const liveIntel  = '/vulns/live';
  static const hackerNews = '/vulns/hacker-news';
}