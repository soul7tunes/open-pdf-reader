import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/recent_store.dart';
import '../theme/app_theme.dart';

/// Settings V2: glass list, dark-mode toggle, the "free forever"
/// promise, app info. Version 1.1.0.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/media-generation-open-pdf-reader-logo-0-58ab363c-35be-4eac-8392-cf66afd8768a.webp',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Free forever',
                      style: TextStyle(
                        fontFamily: AppType.headingFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Open PDF Reader is completely free. No ads, no '
                  'subscription, no in-app purchases, no daily limits, '
                  'and no tracking. Everything works offline, on your '
                  'device.',
                  style: TextStyle(
                    fontFamily: AppType.bodyFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: <Widget>[
                GradientIconChip(
                  icon: settings.darkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Dark mode', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Deep indigo glass — easier on the eyes at night',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.darkMode,
                  onChanged: (value) => settings.setDarkMode(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: <Widget>[
                _SettingsRow(
                  icon: Icons.delete_outline,
                  title: 'Clear recent files',
                  subtitle: 'Removes the list on the Home tab',
                  onTap: () async {
                    await RecentStore.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recent files cleared.'),
                        ),
                      );
                    }
                  },
                ),
                Divider(color: context.glassBorder, height: 24),
                _SettingsRow(
                  icon: Icons.picture_as_pdf,
                  title: 'Open PDF Reader',
                  subtitle: 'Version 1.1.0+2',
                ),
                Divider(color: context.glassBorder, height: 24),
                _SettingsRow(
                  icon: Icons.code,
                  title: 'Package',
                  subtitle: 'com.manish.openpdfreader',
                ),
                Divider(color: context.glassBorder, height: 24),
                _SettingsRow(
                  icon: Icons.favorite_outline,
                  title: 'Made with Flutter',
                  subtitle: 'PDF viewing powered by Pdfium (pdfx)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            GradientIconChip(icon: icon, size: 48, iconSize: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 26,
                color: context.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
