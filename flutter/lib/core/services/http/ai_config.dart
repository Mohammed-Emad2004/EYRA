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

  static const String aiBaseUrl = 'https://eyra-rf7w.onrender.com';

  static const String detectEndpoint = '/api/detect';
  static const Duration requestTimeout = Duration(seconds: 120);
}
