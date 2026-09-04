import 'package:flutter/material.dart';
import 'routes.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/onboarding/pair_glasses_screen.dart';
import '../features/onboarding/connect_audio_screen.dart';
import '../features/onboarding/test_camera_screen.dart';
import '../features/onboarding/ready_screen.dart';
import '../features/home/main_shell.dart';
import '../features/assistance/live_assistance_screen.dart';
import '../features/about/about_screen.dart';
import '../features/developer/developer_monitor_screen.dart';

/// Generates routes by name. Kept intentionally simple (no external
/// routing package) since the navigation graph is linear and small.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
      case AppRoutes.signUp:
        return _page(const SignUpScreen(), settings);
      case AppRoutes.forgotPassword:
        return _page(const ForgotPasswordScreen(), settings);
      case AppRoutes.welcome:
        return _page(const WelcomeScreen(), settings);
      case AppRoutes.pairGlasses:
        return _page(const PairGlassesScreen(), settings);
      case AppRoutes.connectAudio:
        return _page(const ConnectAudioScreen(), settings);
      case AppRoutes.testCamera:
        return _page(const TestCameraScreen(), settings);
      case AppRoutes.onboardingReady:
        return _page(const ReadyScreen(), settings);
      case AppRoutes.main:
        return _page(const MainShell(), settings);
      case AppRoutes.liveAssistance:
        return _page(const LiveAssistanceScreen(), settings);
      case AppRoutes.about:
        return _page(const AboutScreen(), settings);
      case AppRoutes.developerMonitor:
        return _page(const DeveloperMonitorScreen(), settings);
      default:
        return _page(const SplashScreen(), settings);
    }
  }

  static PageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}
