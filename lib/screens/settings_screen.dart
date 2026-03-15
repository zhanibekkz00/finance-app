import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../app.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';
import 'groups/share_code_screen.dart';
import 'groups/join_group_screen.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (v) => ref.read(settingsProvider.notifier).toggleTheme(),
          ),
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(settings.locale.languageCode.toUpperCase()),
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
            title: Text(l10n.exportData),
            onTap: () async {
              await ExportService.exportToFile();
              if (context.mounted)
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.exportSuccess)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l10n.scheduleReminder),
            onTap: () async {
              await NotificationService.instance
                  .scheduleDailyReminder(hour: 9, minute: 0);
              if (context.mounted)
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.reminderSet)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l10n.notifications),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.jointBudget,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: Text(l10n.shareGroupCode),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShareCodeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: Text(l10n.joinGroup),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
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
