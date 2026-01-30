import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../app.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (v) => ref.read(settingsProvider.notifier).toggleTheme(),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(settings.locale.languageCode),
            onTap: () {
              // Cycle through ru, kk, en
              final current = settings.locale.languageCode;
              Locale newLocale;
              if (current == 'ru') {
                newLocale = const Locale('kk');
              } else if (current == 'kk') {
                newLocale = const Locale('en');
              } else {
                newLocale = const Locale('ru');
              }
              ref.read(settingsProvider.notifier).setLocale(newLocale);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            onTap: () async {
              await ExportService.exportToFile();
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export Success')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Schedule Reminder'),
            onTap: () async {
              await NotificationService.instance
                  .scheduleDailyReminder(hour: 9, minute: 0);
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder set for 9:00')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              debugPrint('SettingsScreen: Logout pressed');
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                // Clear the navigation stack and go to onboarding/auth
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.onboarding,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
