import 'package:flutter/material.dart';
import '../state/app_settings_controller.dart';

/// Lightweight, dependency-free localization for Eyra.
///
/// Only the two languages required by the spec are supported:
/// English (LTR) and Arabic (RTL). Strings are looked up by key so the
/// rest of the app never hard-codes user-facing text inline.
class AppStrings {
  AppStrings._();

  static const Map<String, Map<AppLanguage, String>> _values = {
    // Common
    'appName': {AppLanguage.english: 'Eyra', AppLanguage.arabic: 'إيرا'},
    'assistiveVision': {
      AppLanguage.english: 'Assistive Vision',
      AppLanguage.arabic: 'رؤية مساعدة',
    },
    'cancel': {AppLanguage.english: 'Cancel', AppLanguage.arabic: 'إلغاء'},
    'continueLabel': {AppLanguage.english: 'Continue', AppLanguage.arabic: 'متابعة'},

    // Auth
    'welcomeBack': {AppLanguage.english: 'Welcome back', AppLanguage.arabic: 'مرحبًا بعودتك'},
    'continueToEyra': {
      AppLanguage.english: 'Continue to your Eyra experience.',
      AppLanguage.arabic: 'تابع إلى تجربتك مع إيرا.',
    },
    'email': {AppLanguage.english: 'Email', AppLanguage.arabic: 'البريد الإلكتروني'},
    'password': {AppLanguage.english: 'Password', AppLanguage.arabic: 'كلمة المرور'},
    'confirmPassword': {
      AppLanguage.english: 'Confirm password',
      AppLanguage.arabic: 'تأكيد كلمة المرور',
    },
    'logIn': {AppLanguage.english: 'Log in', AppLanguage.arabic: 'تسجيل الدخول'},
    'forgotPassword': {
      AppLanguage.english: 'Forgot password?',
      AppLanguage.arabic: 'نسيت كلمة المرور؟',
    },
    'createAccount': {
      AppLanguage.english: 'Create account',
      AppLanguage.arabic: 'إنشاء حساب',
    },
    'createYourAccount': {
      AppLanguage.english: 'Create your Eyra account',
      AppLanguage.arabic: 'أنشئ حساب إيرا الخاص بك',
    },
    'fullName': {AppLanguage.english: 'Full name', AppLanguage.arabic: 'الاسم الكامل'},
    'alreadyHaveAccount': {
      AppLanguage.english: 'Already have an account? Log in',
      AppLanguage.arabic: 'لديك حساب بالفعل؟ سجّل الدخول',
    },
    'resetYourPassword': {
      AppLanguage.english: 'Reset your password',
      AppLanguage.arabic: 'إعادة تعيين كلمة المرور',
    },
    'sendResetLink': {
      AppLanguage.english: 'Send reset link',
      AppLanguage.arabic: 'إرسال رابط إعادة التعيين',
    },
    'checkYourEmail': {
      AppLanguage.english: 'Check your email',
      AppLanguage.arabic: 'تحقق من بريدك الإلكتروني',
    },
    'resetInstructionsSent': {
      AppLanguage.english:
          'Instructions to reset your password have been sent.',
      AppLanguage.arabic: 'تم إرسال تعليمات إعادة تعيين كلمة المرور.',
    },
    'backToLogin': {AppLanguage.english: 'Back to login', AppLanguage.arabic: 'العودة لتسجيل الدخول'},

    // Onboarding
    'welcomeToEyra': {AppLanguage.english: 'Welcome to Eyra', AppLanguage.arabic: 'مرحبًا بك في إيرا'},
    'letsSetUpGlasses': {
      AppLanguage.english: "Let's set up your smart glasses.",
      AppLanguage.arabic: 'لنقم بإعداد نظارتك الذكية.',
    },
    'pairSmartGlasses': {
      AppLanguage.english: 'Pair Smart Glasses',
      AppLanguage.arabic: 'إقران النظارة الذكية',
    },
    'connectAudio': {AppLanguage.english: 'Connect Audio', AppLanguage.arabic: 'توصيل الصوت'},
    'testCamera': {AppLanguage.english: 'Test Camera', AppLanguage.arabic: 'اختبار الكاميرا'},
    'ready': {AppLanguage.english: 'Ready', AppLanguage.arabic: 'جاهز'},
    'startUsingEyra': {AppLanguage.english: 'Start using Eyra', AppLanguage.arabic: 'ابدأ استخدام إيرا'},

    // Home
    'systemReady': {AppLanguage.english: 'System Ready', AppLanguage.arabic: 'النظام جاهز'},
    'startAssistance': {AppLanguage.english: 'START ASSISTANCE', AppLanguage.arabic: 'بدء المساعدة'},
    'stopAssistance': {AppLanguage.english: 'STOP ASSISTANCE', AppLanguage.arabic: 'إيقاف المساعدة'},
    'glasses': {AppLanguage.english: 'Glasses', AppLanguage.arabic: 'النظارة'},
    'camera': {AppLanguage.english: 'Camera', AppLanguage.arabic: 'الكاميرا'},
    'audio': {AppLanguage.english: 'Audio', AppLanguage.arabic: 'الصوت'},
    'ai': {AppLanguage.english: 'AI', AppLanguage.arabic: 'الذكاء الاصطناعي'},

    // Nav
    'home': {AppLanguage.english: 'Home', AppLanguage.arabic: 'الرئيسية'},
    'devices': {AppLanguage.english: 'Devices', AppLanguage.arabic: 'الأجهزة'},
    'settings': {AppLanguage.english: 'Settings', AppLanguage.arabic: 'الإعدادات'},

    // Live assistance
    'assistanceActive': {AppLanguage.english: 'ASSISTANCE ACTIVE', AppLanguage.arabic: 'المساعدة نشطة'},
    'monitoringEnvironment': {
      AppLanguage.english: 'Monitoring environment...',
      AppLanguage.arabic: 'جارٍ مراقبة المحيط...',
    },

    // Devices
    'smartGlasses': {AppLanguage.english: 'Smart Glasses', AppLanguage.arabic: 'النظارة الذكية'},
    'bluetoothAudio': {AppLanguage.english: 'Bluetooth Audio', AppLanguage.arabic: 'صوت البلوتوث'},
    'battery': {AppLanguage.english: 'Battery', AppLanguage.arabic: 'البطارية'},
    'testAudio': {AppLanguage.english: 'Test Audio', AppLanguage.arabic: 'اختبار الصوت'},
    'reconnect': {AppLanguage.english: 'Reconnect', AppLanguage.arabic: 'إعادة الاتصال'},

    // Settings
    'voiceAlerts': {AppLanguage.english: 'Voice Alerts', AppLanguage.arabic: 'التنبيهات الصوتية'},
    'alertFrequency': {AppLanguage.english: 'Alert Frequency', AppLanguage.arabic: 'تكرار التنبيهات'},
    'language': {AppLanguage.english: 'Language', AppLanguage.arabic: 'اللغة'},
    'highContrast': {AppLanguage.english: 'High Contrast', AppLanguage.arabic: 'التباين العالي'},
    'largeText': {AppLanguage.english: 'Large Text', AppLanguage.arabic: 'نص كبير'},
    'hapticFeedback': {AppLanguage.english: 'Haptic Feedback', AppLanguage.arabic: 'الاهتزاز'},
    'logOut': {AppLanguage.english: 'Log out', AppLanguage.arabic: 'تسجيل الخروج'},
    'about': {AppLanguage.english: 'About', AppLanguage.arabic: 'حول التطبيق'},

    // Developer
    'developerMonitor': {
      AppLanguage.english: 'Developer Monitor',
      AppLanguage.arabic: 'مراقب المطوّر',
    },
  };

  static String of(AppLanguage language, String key) {
    return _values[key]?[language] ?? key;
  }
}

/// Convenience accessor: `context.tr('key')`.
///
/// Uses `watch` (not `read`) so that any widget calling `context.tr(...)`
/// in its `build` method automatically rebuilds when the language
/// changes - this is what makes switching English/Arabic update every
/// screen immediately, not just the one that triggered the change.
extension AppStringsX on BuildContext {
  String tr(String key) {
    final language = AppSettingsController.of(this, listen: true).language;
    return AppStrings.of(language, key);
  }
}
