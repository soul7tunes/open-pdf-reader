import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tool_detail_screen.dart';

/// PDF Tools tab V2: bento grid of glass tiles with gradient icon chips.
/// Every tool is real in V2 — no "coming soon" entries.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('PDF Tools')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          Text(
            'All tools are free —\nno limits, no subscription.',
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.88,
            ),
            itemCount: PdfTool.values.length,
            itemBuilder: (context, i) {
              final tool = PdfTool.values[i];
              return StaggeredIn(
                index: i,
                child: PressScale(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ToolDetailScreen(tool: tool),
                    ),
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GradientIconChip(
                          icon: tool.icon,
                          size: 60,
                          iconSize: 30,
                          gradient: tool.gradient,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tool.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tool.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Ready',
                            style: TextStyle(
                              fontFamily: AppType.headingFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
