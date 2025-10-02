import 'package:esp/base/base_state.dart';

enum GoalMode { daily, monthly }

class HydrationGoalState extends BaseState {
  final double dailyGoalLiters;
  final GoalMode selectedMode;
  final bool isLoading;
  final String? errorMessage;

  const HydrationGoalState({
    this.dailyGoalLiters = 2.5,
    this.selectedMode = GoalMode.daily,
    this.isLoading = false,
    this.errorMessage,
  });

  HydrationGoalState copyWith({
    double? dailyGoalLiters,
    GoalMode? selectedMode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HydrationGoalState(
      dailyGoalLiters: dailyGoalLiters ?? this.dailyGoalLiters,
      selectedMode: selectedMode ?? this.selectedMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [dailyGoalLiters, selectedMode, isLoading, errorMessage];
}
