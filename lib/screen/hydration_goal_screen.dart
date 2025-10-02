import 'package:esp/bloc/cubit/goal_cubit.dart';
import 'package:esp/component/Color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/state/goal_state.dart';

class HydrationGoalScreen extends StatefulWidget {
  const HydrationGoalScreen({Key? key}) : super(key: key);

  @override
  State<HydrationGoalScreen> createState() => _HydrationGoalScreenState();
}

class _HydrationGoalScreenState extends State<HydrationGoalScreen> {
  late TextEditingController _goalController;
  var goalCubit = HydrationGoalCubit();
  GoalMode? _previousMode;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();

    // Load saved goals when screen initializes
    goalCubit.loadGoals();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration Goals'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<HydrationGoalCubit, HydrationGoalState>(
        bloc: goalCubit,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Update text field based on selected mode
          if (_previousMode != state.selectedMode) {
            if (state.selectedMode == GoalMode.daily) {
              _goalController.text = state.dailyGoalLiters.toStringAsFixed(1);
            } else {
              _goalController.text = (state.dailyGoalLiters*30).toStringAsFixed(1);
            }
            _previousMode = state.selectedMode;
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isDaily = state.selectedMode == GoalMode.daily;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary44],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Image(
                        image: AssetImage("assets/image/bottle_logo.png"),
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.water_drop,
                          color: AppColors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Stay Hydrated, Stay Healthy',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary88,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recommended Hydration',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Adult Men',
                                '3.7 liters/day (15.5 cups)',
                                Icons.male,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Adult Women',
                                '2.7 liters/day (11.5 cups)',
                                Icons.female,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'General Average',
                                '2.5-3.0 liters/day (8-10 cups)',
                                Icons.local_drink,
                              ),
                              const Divider(height: 24),
                              Text(
                                '💡 Note: These are general guidelines. Individual needs vary based on activity level, climate, and health conditions.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Goal Mode Selection
                      const Text(
                        'Choose Your Goal Type',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.today, size: 18),
                                  SizedBox(width: 8),
                                  Text('Daily Goal'),
                                ],
                              ),
                              selected: state.selectedMode == GoalMode.daily,
                              onSelected: (selected) {
                                if (selected) {
                                  goalCubit.changeMode(GoalMode.daily);
                                }
                              },
                              selectedColor: AppColors.primaryLow,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: state.selectedMode == GoalMode.daily
                                    ? Colors.blue.shade900
                                    : Colors.grey.shade700,
                                fontWeight: state.selectedMode == GoalMode.daily
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.calendar_month, size: 18),
                                  SizedBox(width: 8),
                                  Text('Monthly Goal'),
                                ],
                              ),
                              selected: state.selectedMode == GoalMode.monthly,
                              onSelected: (selected) {
                                if (selected) {
                                  goalCubit.changeMode(GoalMode.monthly);
                                }
                              },
                              selectedColor: AppColors.primaryLow,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: state.selectedMode == GoalMode.monthly
                                    ? AppColors.secondary
                                    : Colors.grey.shade700,
                                fontWeight:
                                    state.selectedMode == GoalMode.monthly
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Goal Input Section
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isDaily
                                        ? Icons.today
                                        : Icons.calendar_month,
                                    color: AppColors.primary88,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDaily ? 'Daily Goal' : 'Monthly Goal',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _goalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: isDaily
                                      ? 'Liters per day'
                                      : 'Liters per month',
                                  hintText: isDaily
                                      ? 'e.g., 2.5'
                                      : 'e.g., 75.0',
                                  suffixText: 'L',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.water_drop_outlined,
                                  ),
                                ),
                                onChanged: (value) {
                                  final liters = double.tryParse(value);
                                  if (liters != null && liters > 0 && state.dailyGoalLiters != liters) {
                                    if (isDaily && liters <= 10) {
                                      goalCubit.updateDailyGoal(liters);
                                    } else if (!isDaily && liters <= 300) {
                                      goalCubit.updateMonthlyGoal(liters);
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              if (isDaily) ...[
                                Text(
                                  '≈ ${(state.dailyGoalLiters * 4.227).toStringAsFixed(1)} cups per day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '≈ ${((state.dailyGoalLiters * 30) * 4.227).toStringAsFixed(1)} cups per month',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Auto-calculated Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Your Goal Balance',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      '${state.dailyGoalLiters.toStringAsFixed(2)} L',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.grey.shade600,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Monthly',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      '${(state.dailyGoalLiters * 30).toStringAsFixed(2)} L',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              isDaily
                                  ? 'Monthly goal auto-calculated: ${state.dailyGoalLiters.toStringAsFixed(2)} L × 30 days = ${(state.dailyGoalLiters * 30).toStringAsFixed(2)} L'
                                  : 'Daily goal auto-calculated: ${(state.dailyGoalLiters * 30).toStringAsFixed(2)} L ÷ 30 days = ${state.dailyGoalLiters.toStringAsFixed(2)} L',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tips Section
                      Card(
                        elevation: 2,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Hydration Tips',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTip(
                                'Drink water first thing in the morning',
                              ),
                              _buildTip('Carry a reusable water bottle'),
                              _buildTip(
                                'Drink before, during, and after exercise',
                              ),
                              _buildTip('Set reminders throughout the day'),
                              _buildTip(
                                'Track your progress to stay consistent',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary88),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
