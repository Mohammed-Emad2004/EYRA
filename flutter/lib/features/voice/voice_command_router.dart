import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/models/user_settings.dart';
import '../../core/models/voice_command.dart';
import '../../core/state/assistance_controller.dart';
import '../../core/state/device_controller.dart';
import '../../core/state/voice_command_controller.dart';

/// Widget that subscribes to [VoiceCommandController.onCommand] and
/// routes classified commands to the appropriate controller methods.
///
/// This widget has no visual presence — it only exists to bridge the
/// voice-command event stream to the existing controller layer. It
/// wraps [child] and passes it through unchanged.
///
/// Lives inside the authenticated (or unauthenticated) provider tree
/// so it has access to all tier-2 controllers via [Provider.of].
class VoiceCommandRouter extends StatefulWidget {
  final Widget child;
  const VoiceCommandRouter({required this.child, super.key});

  @override
  State<VoiceCommandRouter> createState() => _VoiceCommandRouterState();
}

class _VoiceCommandRouterState extends State<VoiceCommandRouter> {
  StreamSubscription<VoiceCommand>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription == null) {
      final vc = Provider.of<VoiceCommandController>(context, listen: false);
      _subscription = vc.onCommand.listen(_onCommand);
    }
  }

  void _onCommand(VoiceCommand command) {
    if (!mounted) return;

    final assistance =
        Provider.of<AssistanceController>(context, listen: false);
    final device = Provider.of<DeviceController>(context, listen: false);
    final vc =
        Provider.of<VoiceCommandController>(context, listen: false);
    final isArabic = vc.appLanguage == AppLanguage.arabic;

    switch (command.type) {
      case VoiceCommandType.startAssistance:
        assistance.startAssistance();
        vc.textToSpeechService.speak(
            isArabic ? 'جارٍ بدء المساعده' : 'Starting assistance');
        break;

      case VoiceCommandType.stopAssistance:
        assistance.stopAssistance();
        vc.textToSpeechService.speak(
            isArabic ? 'تم إيقاف المساعده' : 'Assistance stopped');
        break;

      case VoiceCommandType.repeat:
        vc.textToSpeechService.repeatLast();
        break;

      case VoiceCommandType.deviceStatus:
        _speakDeviceStatus(device, vc, isArabic);
        break;

      case VoiceCommandType.settings:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.main,
          (route) => false,
        );
        vc.textToSpeechService.speak(
            isArabic ? 'جارٍ فتح الإعدادات' : 'Opening settings');
        break;

      case VoiceCommandType.emergency:
        vc.textToSpeechService.speak(isArabic
            ? 'ميزة الطوارئ قادمه قريبا'
            : 'Emergency feature coming soon');
        break;

      case VoiceCommandType.confirmYes:
      case VoiceCommandType.confirmNo:
      case VoiceCommandType.unrecognized:
        break;
    }
  }

  void _speakDeviceStatus(
      DeviceController device, VoiceCommandController vc, bool isArabic) {
    final parts = <String>[
      isArabic ? 'النظاره: ${device.glassesStatus.name}'
          : 'Glasses: ${device.glassesStatus.name}',
      isArabic ? 'الكاميرا: ${device.cameraStatus.name}'
          : 'Camera: ${device.cameraStatus.name}',
      isArabic ? 'الصوت: ${device.audioStatus.name}'
          : 'Audio: ${device.audioStatus.name}',
    ];
    if (device.batteryPercent != null) {
      parts.add(isArabic
          ? 'البطاريه: ${device.batteryPercent}-percent'
          : 'Battery: ${device.batteryPercent} percent');
    }
    vc.textToSpeechService.speak(parts.join('. '));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
