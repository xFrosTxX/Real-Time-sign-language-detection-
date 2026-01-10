import 'package:flutter/material.dart';
import 'package:flutter_app/data/notifiers.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final mutedTextColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // App Title
              Text(
                "GestureWise",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Real-time Sign Language Recognition",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: mutedTextColor,
                ),
              ),

              const SizedBox(height: 18),

              // Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.25),
                      cs.primary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.pan_tool_alt_rounded,
                        color: cs.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Point your camera at a hand sign and get instant text output.",
                        style:
                            theme.textTheme.bodyLarge?.copyWith(height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Start Detection
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text("Start Detection"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    // Switch to Camera tab
                    selectedPageNotifier.value = 1;
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Tips Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text("Tips for better detection"),
                  onPressed: () => _showTips(context),
                ),
              ),

              const SizedBox(height: 20),

              // How it works
              Text(
                "How it works",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              const _StepTile(
                index: "1",
                title: "Open Camera",
                subtitle: "Tap Start Detection or the Camera tab.",
                icon: Icons.videocam_outlined,
              ),
              const _StepTile(
                index: "2",
                title: "Show a Sign",
                subtitle: "Keep your hand centered and well-lit.",
                icon: Icons.center_focus_strong_outlined,
              ),
              const _StepTile(
                index: "3",
                title: "Get Output",
                subtitle: "The app converts signs into readable text.",
                icon: Icons.translate_outlined,
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  static void _showTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Tips for better detection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text("• Use good lighting (avoid dark rooms)."),
              Text("• Keep your hand inside the frame."),
              Text("• Use a plain background if possible."),
              Text("• Hold the sign steady for 1–2 seconds."),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  final String index;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Text(
              index,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(icon, color: cs.primary.withValues(alpha: 0.80)),
        ],
      ),
    );
  }
}
