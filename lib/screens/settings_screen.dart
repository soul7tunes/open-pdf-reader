import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/recent_store.dart';

/// Settings: dark mode, the "free forever" promise, app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    'Free forever',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Open PDF Reader is completely free. No ads, no '
                    'subscription, no in-app purchases, no daily limits, '
                    'and no tracking. Everything works offline, on your '
                    'device.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Easier on the eyes at night'),
            value: settings.darkMode,
            onChanged: (value) => settings.setDarkMode(value),
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear recent files'),
            subtitle: const Text('Removes the list on the Home tab'),
            leading: const Icon(Icons.delete_outline),
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
          const Divider(),
          const ListTile(
            title: Text('Open PDF Reader'),
            subtitle: Text('Version 1.0.0+1'),
            leading: Icon(Icons.picture_as_pdf),
          ),
          const ListTile(
            title: Text('Package'),
            subtitle: Text('com.manish.openpdfreader'),
            leading: Icon(Icons.code),
          ),
          const ListTile(
            title: Text('Made with Flutter'),
            subtitle: Text('PDF viewing powered by Pdfium (pdfx)'),
            leading: Icon(Icons.favorite_outline),
          ),
        ],
      ),
    );
  }
}
