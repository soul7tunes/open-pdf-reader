import 'package:flutter/material.dart';

import 'tool_detail_screen.dart';

/// The six PDF tools. Every entry opens a real screen; tools that are not
/// finished in V1 say so on their own screen and still let the user pick
/// the input files.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'All tools are free — no limits, no subscription.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...PdfTool.values.map(
            (tool) => Card(
              child: ListTile(
                leading: Icon(tool.icon, size: 32),
                title: Text(tool.title),
                subtitle: Text(tool.description),
                trailing: tool.readyInV1
                    ? const Chip(label: Text('Ready'))
                    : const Chip(label: Text('Coming soon')),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ToolDetailScreen(tool: tool),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
