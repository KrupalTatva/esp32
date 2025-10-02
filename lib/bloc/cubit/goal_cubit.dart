import 'package:esp/base/base_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/goal_state.dart';

class HydrationGoalCubit extends Cubit<HydrationGoalState> {
  static const String _dailyGoalKey = 'hydration_goal';
  static const String _goalModeKey = 'goal_mode';

  HydrationGoalCubit() : super(const HydrationGoalState());

  Future<void> loadGoals() async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyGoal = prefs.getDouble(_dailyGoalKey) ?? 2.5;
      final modeIndex = prefs.getInt(_goalModeKey) ?? 0;
      final mode = GoalMode.values[modeIndex];

      emit(state.copyWith(
        dailyGoalLiters: dailyGoal,
        selectedMode: mode,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load goals: $e',
      ));
    }
  }

  Future<void> changeMode(GoalMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_goalModeKey, mode.index);

      emit(state.copyWith(selectedMode: mode));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to change mode: $e'));
    }
  }

  Future<void> updateDailyGoal(double liters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_dailyGoalKey, liters);

      emit(state.copyWith(
        dailyGoalLiters: liters,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save daily goal: $e'));
    }
  }

  Future<void> updateMonthlyGoal(double liters) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Auto-calculate daily goal from monthly (monthly / 30)
      final dailyGoal = liters / 30;
      await prefs.setDouble(_dailyGoalKey, dailyGoal);

      emit(state.copyWith(
        dailyGoalLiters: dailyGoal,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save monthly goal: $e'));
    }
  }
}
