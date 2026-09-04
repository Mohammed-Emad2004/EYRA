import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../devices/devices_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Hosts the three primary destinations (Home, Devices, Settings) behind
/// a bottom navigation bar, as specified by the main navigation graph.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    DevicesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.devices_other_outlined),
            activeIcon: const Icon(Icons.devices_rounded),
            label: context.tr('devices'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings_rounded),
            label: context.tr('settings'),
          ),
        ],
      ),
    );
  }
}
