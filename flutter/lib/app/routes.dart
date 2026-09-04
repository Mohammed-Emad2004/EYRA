/// Centralized route name constants for the whole app.
class AppRoutes {
  AppRoutes._();

  // Auth
  static const splash = '/';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';

  // Onboarding
  static const welcome = '/onboarding/welcome';
  static const pairGlasses = '/onboarding/pair-glasses';
  static const connectAudio = '/onboarding/connect-audio';
  static const testCamera = '/onboarding/test-camera';
  static const onboardingReady = '/onboarding/ready';

  // Main shell (bottom nav: home / devices / settings)
  static const main = '/main';

  // Pushed from main shell
  static const liveAssistance = '/assistance';
  static const about = '/about';
  static const developerMonitor = '/developer-monitor';
}
