import 'package:esp/base/base_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../service/water_reminder_worker.dart';
import '../../service/notification_service.dart';
import '../state/water_reminder_state.dart';

class WaterReminderCubit extends Cubit<BaseState> {
  WaterReminderCubit() : super(BaseInitState());

  static const List<int> _availableIntervals = [15, 30, 60, 120, 180, 240, 300, 360, 420, 480];
  static const int _defaultDailyGoal = 8; // 8 glasses of water per day

  Future<void> initializeApp() async {
    try {
      emit(LoadingState());

      // Initialize notification service
      await NotificationService.initialize();

      await _loadCurrentSettings();
    } catch (e) {
      emit(ErrorState(errorMessage: 'Failed to initialize app: ${e.toString()}'));
    }
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final isActive = await WaterReminderService.isReminderActive();
      final interval = await WaterReminderService.getCurrentInterval();
      final waterGlasses = await WaterReminderService.getTodayWaterGlasses();

      emit(WaterReminderLoaded(
        isReminderActive: isActive,
        selectedInterval: interval,
        todayWaterGlasses: waterGlasses,
        dailyGoal: _defaultDailyGoal,
        availableIntervals: _availableIntervals,
      ));
    } catch (e) {
      emit(ErrorState(errorMessage: 'Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> startReminder(int intervalHours) async {
    final currentState = state;
    if (currentState is! WaterReminderLoaded) return;

    try {
      emit(LoadingState());

      await WaterReminderService.startWaterReminder(intervalHours);

      emit(currentState.copyWith(
        isReminderActive: true,
        selectedInterval: intervalHours,
      ));

      // Show success message
      emit(WaterReminderSuccess(
          'Water reminder started! You\'ll get notifications every $intervalHours hour${intervalHours > 1 ? 's' : ''}'
      ));

      // Return to loaded state
      emit(currentState.copyWith(
        isReminderActive: true,
        selectedInterval: intervalHours,
      ));

    } catch (e) {
      emit(ErrorState(errorMessage: 'Failed to start reminder: ${e.toString()}'));
      // Return to previous state on error
      emit(currentState);
    }
  }

  Future<void> stopReminder() async {
    final currentState = state;
    if (currentState is! WaterReminderLoaded) return;

    try {
      emit(LoadingState());

      await WaterReminderService.stopWaterReminder();

      emit(currentState.copyWith(isReminderActive: false));

      // Show success message
      emit(const WaterReminderSuccess('Water reminder stopped'));

      // Return to loaded state
      emit(currentState.copyWith(isReminderActive: false));

    } catch (e) {
      emit(ErrorState(errorMessage: 'Failed to stop reminder: ${e.toString()}'));
      // Return to previous state on error
      emit(currentState);
    }
  }

  Future<void> markWaterConsumed() async {
    final currentState = state;
    if (currentState is! WaterReminderLoaded) return;

    try {
      await WaterReminderService.markWaterConsumed();
      final newWaterCount = await WaterReminderService.getTodayWaterGlasses();

      emit(currentState.copyWith(todayWaterGlasses: newWaterCount));

      // Show success message
      emit(const WaterReminderSuccess('Great! Keep staying hydrated! 💧'));

      // Return to loaded state with updated count
      emit(currentState.copyWith(todayWaterGlasses: newWaterCount));

    } catch (e) {
      emit(ErrorState(errorMessage: 'Failed to mark water consumed: ${e.toString()}'));
      // Return to previous state on error
      emit(currentState);
    }
  }

  Future<void> testNotification() async {
    try {
      await NotificationService.showWaterReminderNotification();
      emit(const WaterReminderSuccess('Test notification sent!'));

      // Return to previous state after showing success
      final currentState = state;
      if (currentState is WaterReminderLoaded) {
        emit(currentState);
      } else {
        await _loadCurrentSettings();
      }
    } catch (e) {
      emit(ErrorState(errorMessage: 'Failed to send test notification: ${e.toString()}'));
    }
  }

  void updateSelectedInterval(int interval) {
    final currentState = state;
    if (currentState is WaterReminderLoaded) {
      emit(currentState.copyWith(selectedInterval: interval));
    }
  }

  Future<void> refreshData() async {
    await _loadCurrentSettings();
  }

  void clearMessages() {
    final currentState = state;
    if (currentState is WaterReminderLoaded) {
      emit(currentState);
    } else if (state is ErrorState || state is WaterReminderSuccess) {
      _loadCurrentSettings();
    }
  }
}