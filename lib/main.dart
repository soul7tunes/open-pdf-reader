import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tools_screen.dart';
import 'services/app_settings.dart';
import 'theme/app_theme.dart';

/// Open PDF Reader — works offline.
void main() {
  runApp(const OpenPdfReaderApp());
}

class OpenPdfReaderApp extends StatefulWidget {
  const OpenPdfReaderApp({super.key});

  @override
  State<OpenPdfReaderApp> createState() => _OpenPdfReaderAppState();
}

class _OpenPdfReaderAppState extends State<OpenPdfReaderApp> {
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Open PDF Reader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _settings.themeMode,
          home: MainTabs(settings: _settings),
        );
      },
    );
  }
}

class MainTabs extends StatefulWidget {
  const MainTabs({required this.settings, super.key});

  final AppSettings settings;

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _index = 0;

  static const List<({IconData icon, IconData activeIcon, String label})>
      _tabs = <({IconData icon, IconData activeIcon, String label})>[
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Tools'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const ToolsScreen(),
      SettingsScreen(settings: widget.settings),
    ];
    return Scaffold(
      body: GlassBackground(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: FloatingGlassBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                for (var i = 0; i < _tabs.length; i++)
                  _NavItem(
                    icon: _tabs[i].icon,
                    activeIcon: _tabs[i].activeIcon,
                    label: _tabs[i].label,
                    selected: _index == i,
                    onTap: () => setState(() => _index = i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected ? AppColors.brandGradient : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            selected ? activeIcon : icon,
            size: 24,
            color: selected ? Colors.white : context.textSecondary,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppType.headingFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.textSecondary,
            ),
          ),
        ],
      ),
    );
    return PressScale(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: content,
      ),
    );
  }
}
