import 'package:esp/base/base_state.dart';

class WaterReminderLoaded extends BaseState {
  final bool isReminderActive;
  final int selectedInterval;
  final int todayWaterGlasses;
  final int dailyGoal;
  final List<int> availableIntervals;

  const WaterReminderLoaded({
    required this.isReminderActive,
    this.selectedInterval = 1,
    required this.todayWaterGlasses,
    required this.dailyGoal,
    required this.availableIntervals,
  });

  @override
  List<Object> get props => [
    isReminderActive,
    selectedInterval,
    todayWaterGlasses,
    dailyGoal,
    availableIntervals,
  ];

  WaterReminderLoaded copyWith({
    bool? isReminderActive,
    int? selectedInterval,
    int? todayWaterGlasses,
    int? dailyGoal,
    List<int>? availableIntervals,
  }) {
    return WaterReminderLoaded(
      isReminderActive: isReminderActive ?? this.isReminderActive,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      todayWaterGlasses: todayWaterGlasses ?? this.todayWaterGlasses,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      availableIntervals: availableIntervals ?? this.availableIntervals,
    );
  }

  double get waterProgress => todayWaterGlasses / dailyGoal;
}

class WaterReminderSuccess extends BaseState {
  final String message;

  const WaterReminderSuccess(this.message);

  @override
  List<Object> get props => [message];
}