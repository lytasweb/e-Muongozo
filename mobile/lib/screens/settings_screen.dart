import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/role_provider.dart';
import '../providers/settings_provider.dart';
import '../services/db_service.dart';
import 'p2p_share_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final role = ref.watch(roleProvider);
    final roleNotifier = ref.read(roleProvider.notifier);
    final isTeacher = role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ============================================================
          // ROLE — Teacher mode toggle
          // ============================================================
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isTeacher
                  ? const Color(0xFF1E2050)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isTeacher
                    ? const Color(0xFF1E2050)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isTeacher
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFF1E2050)
                            .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isTeacher ? '👩‍🏫' : '🎓',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isTeacher
                              ? Colors.white
                              : const Color(0xFF1E2050),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTeacher
                            ? 'Showing teaching schemes & recommended books.'
                            : 'Currently showing the student view.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isTeacher
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey[600],
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isTeacher,
                  onChanged: (v) {
                    roleNotifier.setRole(
                      v ? UserRole.teacher : UserRole.student,
                    );
                  },
                  activeTrackColor: Colors.white24,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // ============================================================
          // APPEARANCE
          // ============================================================
          const _SectionTitle('Appearance'),

          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(prefs.themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: prefs.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(
                    value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (v) {
                if (v != null) notifier.setTheme(v);
              },
            ),
          ),

          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Font size'),
            subtitle: Text(_fontLabel(prefs.fontSize)),
            trailing: DropdownButton<AppFontSize>(
              value: prefs.fontSize,
              underline: const SizedBox.shrink(),
              items: AppFontSize.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_fontLabel(s)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setFontSize(v);
              },
            ),
          ),

          const Divider(height: 24),

          // ============================================================
          // DOWNLOADS
          // ============================================================

          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share offline'),
            subtitle: const Text(
                'Send to a classmate over Bluetooth / Wi-Fi Direct'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const P2PShareScreen()),
            ),
          ),
          const Divider(height: 24),
          const _SectionTitle('Downloads'),

          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('Wi-Fi only downloads'),
            subtitle: const Text('Only sync when connected to Wi-Fi'),
            value: prefs.wifiOnly,
            onChanged: notifier.setWifiOnly,
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: Colors.redAccent),
            title: const Text('Clear all downloaded content'),
            subtitle:
                const Text('Deletes subjects, topics, blocks, bookmarks'),
            onTap: () => _confirmClear(context),
          ),

          const Divider(height: 24),

          // ============================================================
          // ABOUT
          // ============================================================
          const _SectionTitle('About'),

          const AboutListTile(
            icon: Icon(Icons.school_outlined),
            applicationName: 'e-Muongozo',
            applicationVersion: '1.0.0',
            applicationLegalese: '© e-Muongozo',
            child: Text('About e-Muongozo'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.system:
        return 'Follow system';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  static String _fontLabel(AppFontSize f) {
    switch (f) {
      case AppFontSize.small:
        return 'Small';
      case AppFontSize.medium:
        return 'Medium';
      case AppFontSize.large:
        return 'Large';
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'This deletes all downloaded subjects, topics, blocks, '
          'bookmarks, and progress. You can re-sync later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await DbService.resetDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey[600],
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
