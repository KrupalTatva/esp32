import 'package:esp/screen/WaterIntake.dart';
import 'package:esp/screen/create_account_screen.dart';
import 'package:flutter/material.dart';

import '../screen/AnalyticsScreen.dart';
import '../screen/ble_connection_screen.dart';
import '../screen/dashboard_screen.dart';
import '../screen/hydration_goal_screen.dart';
import '../screen/login_screen.dart';
import '../screen/reminder_screeen.dart';

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String createAccount = '/createAccount';
  static const String setReminderScreen = '/setReminderScreen';
  static const String trackingScreen = '/trackingScreen';
  static const String hydrationGoalScreen = '/hydrationGoalScreen';
  static const String analyticsScreen = '/analyticsScreen';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case createAccount:
        return MaterialPageRoute(builder: (_) => CreateAccountScreen());
      case setReminderScreen:
        return MaterialPageRoute(builder: (_) => WaterReminderScreen());
      case trackingScreen:
        return MaterialPageRoute(builder: (_) => BleConnectionScreen());
      case hydrationGoalScreen:
        return MaterialPageRoute(builder: (_) => HydrationGoalScreen());
      case analyticsScreen:
        return MaterialPageRoute(builder: (_) => AnalyticsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  static void navigateToDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, dashboard, (route) => false);
  }
}
