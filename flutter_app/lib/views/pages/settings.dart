import 'package:flutter/material.dart';
import 'package:flutter_app/data/notifiers.dart';
import 'package:flutter_app/views/pages/about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Reset navbar to Home
    selectedPageNotifier.value = 0;

    // Go back to first screen (Welcome / Login)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🌗 Theme toggle
            ValueListenableBuilder<bool>(
              valueListenable: selectedDarkModeNotifier,
              builder: (context, isDark, _) {
                return SwitchListTile(
                  title: const Text("Dark Mode"),
                  subtitle: Text(isDark ? "Enabled" : "Disabled"),
                  value: isDark,
                  onChanged: (val) => selectedDarkModeNotifier.value = val,
                  secondary: const Icon(Icons.dark_mode_outlined),
                );
              },
            ),

            const Divider(),

            /// ℹ️ About
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About"),
              subtitle: const Text("App information"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutPage(),
                  ),
                );
              },
            ),

            const Divider(),

            /// 🔓 Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              subtitle: const Text("Sign out of your account"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
