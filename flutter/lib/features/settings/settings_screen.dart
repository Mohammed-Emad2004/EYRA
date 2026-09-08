import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/state/app_settings_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/toggle_row.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('settings'), style: theme.textTheme.displayMedium),

            const SectionHeader(title: 'Theme'),
            _ThemeRow(settings: settings),

            const SectionHeader(title: 'Alerts'),
            ToggleRow(
              label: context.tr('voiceAlerts'),
              subtitle: 'Speak obstacle alerts out loud',
              icon: Icons.record_voice_over_outlined,
              value: settings.voiceAlerts,
              onChanged: (v) => settings.setVoiceAlerts(v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AlertFrequencyRow(settings: settings),

            const SectionHeader(title: 'Language'),
            _LanguageRow(settings: settings),

            const SectionHeader(title: 'Accessibility'),
            ToggleRow(
              label: context.tr('highContrast'),
              subtitle: 'Increase text and border contrast',
              icon: Icons.contrast_rounded,
              value: settings.highContrast,
              onChanged: (v) => settings.setHighContrast(v),
            ),
            const SizedBox(height: AppSpacing.sm),
            ToggleRow(
              label: context.tr('largeText'),
              subtitle: 'Increase text size throughout Eyra',
              icon: Icons.text_increase_rounded,
              value: settings.largeText,
              onChanged: (v) => settings.setLargeText(v),
            ),
            const SizedBox(height: AppSpacing.sm),
            ToggleRow(
              label: context.tr('hapticFeedback'),
              subtitle: 'Vibrate on important alerts',
              icon: Icons.vibration_rounded,
              value: settings.hapticFeedback,
              onChanged: (v) => settings.setHapticFeedback(v),
            ),

            const SectionHeader(title: 'More'),
            _NavRow(
              icon: Icons.info_outline_rounded,
              label: context.tr('about'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.about),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavRow(
              icon: Icons.developer_mode_outlined,
              label: 'Developer Monitor',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.developerMonitor),
            ),

            const SizedBox(height: AppSpacing.xl),
            _LogOutRow(
              onTap: () {
                AuthController.of(context).logOut();
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final AppSettingsController settings;
  const _ThemeRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, color: cs.secondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(context.tr('theme'), style: Theme.of(context).textTheme.bodyLarge),
          ),
          _ThemeChoiceChip(
            label: context.tr('themeLight'),
            icon: Icons.light_mode_outlined,
            selected: settings.themeMode == AppThemeMode.light,
            onTap: () => settings.setThemeMode(AppThemeMode.light),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ThemeChoiceChip(
            label: context.tr('themeDark'),
            icon: Icons.dark_mode_outlined,
            selected: settings.themeMode == AppThemeMode.dark,
            onTap: () => settings.setThemeMode(AppThemeMode.dark),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ThemeChoiceChip(
            label: context.tr('themeSystem'),
            icon: Icons.settings_brightness_outlined,
            selected: settings.themeMode == AppThemeMode.system,
            onTap: () => settings.setThemeMode(AppThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? cs.secondary.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? cs.secondary : (Theme.of(context).dividerTheme.color ?? cs.outline)),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: selected ? cs.secondary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppSettingsController settings;
  const _LanguageRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.language_rounded, color: cs.secondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(context.tr('language'), style: Theme.of(context).textTheme.bodyLarge),
          ),
          _LanguageChoiceChip(
            label: 'English',
            selected: settings.language == AppLanguage.english,
            onTap: () => settings.setLanguage(AppLanguage.english),
          ),
          const SizedBox(width: AppSpacing.xs),
          _LanguageChoiceChip(
            label: 'العربية',
            selected: settings.language == AppLanguage.arabic,
            onTap: () => settings.setLanguage(AppLanguage.arabic),
          ),
        ],
      ),
    );
  }
}

class _LanguageChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? cs.secondary.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? cs.secondary : (Theme.of(context).dividerTheme.color ?? cs.outline)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? cs.secondary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertFrequencyRow extends StatelessWidget {
  final AppSettingsController settings;
  const _AlertFrequencyRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: cs.secondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(context.tr('alertFrequency'), style: Theme.of(context).textTheme.bodyLarge),
          ),
          DropdownButton<AlertFrequency>(
            value: settings.alertFrequency,
            dropdownColor: cs.surface,
            underline: const SizedBox.shrink(),
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (value) {
              if (value != null) unawaited(settings.setAlertFrequency(value));
            },
            items: AlertFrequency.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget + 16),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
            ),
            child: Row(
              children: [
                Icon(icon, color: cs.secondary, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogOutRow extends StatelessWidget {
  final VoidCallback onTap;
  const _LogOutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.tr('logOut'),
      child: Material(
        color: cs.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget + 16),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: cs.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: cs.error, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.tr('logOut'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
