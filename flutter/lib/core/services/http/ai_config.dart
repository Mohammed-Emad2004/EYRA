/// ─────────────────────────────────────────────────────────────────────────────
/// AI service configuration.
///
/// Set [aiBaseUrl] to the LAN IP address of the PC running the EYRA AI
/// Flask service (python run.py / run.bat).  The AI service binds to
/// 0.0.0.0:5000, so use the PC's LAN IP visible from the Android device —
/// never 127.0.0.1 or localhost.
///
/// ⚠ DEV CONFIGURATION — update this before running on device:
///   Replace the IP below with your PC's actual LAN IP address.
///   You can find it with `ipconfig` (Windows) or `ip addr` (Linux/Mac).
///
/// Example: 'http://192.168.1.42:5000'
/// ─────────────────────────────────────────────────────────────────────────────
class AiConfig {
  AiConfig._();

  // TODO(dev): Confirm this is still your PC's LAN IP before each session.
  // Updated via ipconfig on 2026-09-10: 192.168.1.11 (was 100.100.100.46)
  static const String aiBaseUrl = 'http://100.100.100.46:5000';

  static const String detectEndpoint = '/api/detect';
  static const Duration requestTimeout = Duration(seconds: 10);
}
