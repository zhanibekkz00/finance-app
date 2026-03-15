import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'widgets/admin_wrapper.dart';
import 'screens/notifications_screen.dart';

import 'l10n/generated/app_localizations.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login =
      '/login'; // Keep the route name but use AuthScreen
  static const String dashboard = '/dashboard';
  static const String addTransaction = '/add_transaction';
  static const String settings = '/settings';
  static const String admin = '/admin';
  static const String notifications = '/notifications';
}

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    Widget home;
    if (auth.status == AuthStatus.loading) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (auth.status == AuthStatus.authenticated) {
      if (auth.role == 'admin') {
        home = const AdminHomeScreen();
      } else {
        home = const DashboardScreen();
      }
    } else {
      home = const OnboardingScreen();
    }

    return MaterialApp(
      title: 'Finance App',
      debugShowCheckedModeBanner: false,
      theme: settings.themeMode == ThemeMode.dark
          ? ThemeData.dark()
          : ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
      routes: {
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const AuthScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.addTransaction: (context) => const AddTransactionScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.admin: (context) =>
            const AdminWrapper(child: AdminHomeScreen()),
        AppRoutes.notifications: (context) => const NotificationsScreen(),
      },
    );
  }
}
