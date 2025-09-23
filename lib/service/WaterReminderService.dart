import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class WaterReminderService {
  static const String taskName = 'waterReminderTask';
  static const String uniqueName = 'waterReminderWork';

  static Future<void> startWaterReminder(int intervalHours) async {
    // Cancel existing work
    await stopWaterReminder();

    // Save reminder settings
    await _saveReminderSettings(intervalHours, true);

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      initialDelay: Duration(seconds: 15),
      frequency: Duration(hours: intervalHours),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'intervalHours': intervalHours,
        'startTime': DateTime.now().millisecondsSinceEpoch,
      },
    );

    print('Water reminder started with ${intervalHours}h interval');
  }

  static Future<void> stopWaterReminder() async {
    await Workmanager().cancelByUniqueName(uniqueName);
    await _saveReminderSettings(0, false);
    print('Water reminder stopped');
  }

  static Future<bool> isReminderActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_active') ?? false;
  }

  static Future<int> getCurrentInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reminder_interval') ?? 1;
  }

  static Future<void> _saveReminderSettings(int intervalHours, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_interval', intervalHours);
    await prefs.setBool('reminder_active', isActive);
  }

  // This method is called from the background task
  static Future<bool> showWaterReminderNotification() async {
    try {
      await NotificationService.showWaterReminderNotification();
      await _updateWaterStats();
      return true;
    } catch (e) {
      print('Error showing water reminder notification: $e');
      return false;
    }
  }

  static Future<void> _updateWaterStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastReminderDate = prefs.getString('last_reminder_date') ?? '';

    if (today != lastReminderDate) {
      // Reset daily count for new day
      await prefs.setInt('daily_reminders_sent', 1);
      await prefs.setString('last_reminder_date', today);
    } else {
      final currentCount = prefs.getInt('daily_reminders_sent') ?? 0;
      await prefs.setInt('daily_reminders_sent', currentCount + 1);
    }
  }

  static Future<void> markWaterConsumed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastConsumedDate = prefs.getString('last_consumed_date') ?? '';

    if (today != lastConsumedDate) {
      await prefs.setInt('daily_water_glasses', 1);
      await prefs.setString('last_consumed_date', today);
    } else {
      final currentCount = prefs.getInt('daily_water_glasses') ?? 0;
      await prefs.setInt('daily_water_glasses', currentCount + 1);
    }
  }

  static Future<int> getTodayWaterGlasses() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastConsumedDate = prefs.getString('last_consumed_date') ?? '';

    if (today == lastConsumedDate) {
      return prefs.getInt('daily_water_glasses') ?? 0;
    }
    return 0;
  }
}