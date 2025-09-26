import 'package:esp/base/base_state.dart';
import 'package:esp/component/Color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit/water_reminder_cubit.dart';
import '../bloc/state/water_reminder_state.dart';

class WaterReminderScreen extends StatelessWidget {
  const WaterReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WaterReminderCubit()..initializeApp(),
      child: const WaterReminderView(),
    );
  }
}

class WaterReminderView extends StatelessWidget {
  const WaterReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Reminder'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.read<WaterReminderCubit>().refreshData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<WaterReminderCubit, BaseState>(
        listener: (context, state) {
          if (state is WaterReminderSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is ErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? ""),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => context.read<WaterReminderCubit>().initializeApp(),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Container(
            height: double.maxFinite,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primary88, AppColors.primary44, AppColors.white],
              ),
            ),
            child: SafeArea(
              child: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BaseState state) {
    if (state is LoadingState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (state is WaterReminderLoaded) {
      return _buildLoadedContent(context, state);
    }

    if (state is ErrorState) {
      return _buildErrorContent(context, state);
    }

    if (state is WaterReminderSuccess) {
      // This will be handled by BlocConsumer listener, but we need to return something
      return const Center(child: CircularProgressIndicator());
    }

    return const Center(
      child: Text(
        'Initializing...',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, WaterReminderLoaded state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Water intake progress card
            // _buildWaterIntakeCard(context, state),

            const SizedBox(height: 20),

            // Reminder settings card
            _buildReminderSettingsCard(context, state),

            const SizedBox(height: 20),

            // Status indicator
            _buildStatusIndicator(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterIntakeCard(BuildContext context, WaterReminderLoaded state) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.local_drink, size: 60, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Today\'s Water Intake',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${state.todayWaterGlasses} / ${state.dailyGoal} glasses',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: state.waterProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.waterProgress * 100).toInt()}% of daily goal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: () => context.read<WaterReminderCubit>().markWaterConsumed(),
            //   icon: const Icon(Icons.add),
            //   label: const Text('I drank water'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primary,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettingsCard(BuildContext context, WaterReminderLoaded state) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isReminderActive ? Icons.notifications_active : Icons.notifications_off,
                  color: state.isReminderActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reminder Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Remind me every: ${formattedInterval(state.selectedInterval > 0 ? state.selectedInterval : state.availableIntervals.first)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),
            Slider(
              value: state.availableIntervals.contains(state.selectedInterval)
                  ? state.availableIntervals.indexOf(state.selectedInterval).toDouble()
                  : 0, // fallback to first element
              min: 0,
              max: (state.availableIntervals.length - 1).toDouble(),
              divisions: state.availableIntervals.length - 1,
              label: formattedInterval(state.selectedInterval > 0 ? state.selectedInterval : state.availableIntervals.first),
              onChanged: (double value) {
                int index = value.round();
                context
                    .read<WaterReminderCubit>()
                    .updateSelectedInterval(state.availableIntervals[index]);
              },
            ),

            // DropdownButtonFormField<int>(
            //   initialValue: state.selectedInterval,
            //   decoration: InputDecoration(
            //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            //     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //   ),
            //   items: state.availableIntervals.map((int value) {
            //     return DropdownMenuItem<int>(
            //       value: value,
            //       child: Text(formattedInterval(value)),
            //     );
            //   }).toList(),
            //   onChanged: (int? newValue) {
            //     if (newValue != null) {
            //       context.read<WaterReminderCubit>().updateSelectedInterval(newValue);
            //     }
            //   },
            // ),

            const SizedBox(height: 20),

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isReminderActive
                        ? () => context.read<WaterReminderCubit>().stopReminder()
                        : () => context.read<WaterReminderCubit>().startReminder(state.selectedInterval),
                    icon: Icon(state.isReminderActive ? Icons.stop : Icons.play_arrow),
                    label: Text(state.isReminderActive ? 'Stop Reminder' : 'Start Reminder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isReminderActive ? AppColors.green : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<WaterReminderCubit>().testNotification(),
                    icon: const Icon(Icons.mobile_friendly),
                    label: const Text('Test Notification'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formattedInterval(int selectedMinutes) {
    if (selectedMinutes < 60) {
      return "$selectedMinutes mins";
    } else {
      int hours = selectedMinutes ~/ 60;
      return "$hours hour${hours > 1 ? 's' : ''}";
    }
  }

  Widget _buildStatusIndicator(BuildContext context, WaterReminderLoaded state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: state.isReminderActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.isReminderActive ? Colors.green : AppColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.isReminderActive ? Icons.check_circle : Icons.pause_circle,
            color: state.isReminderActive ? Colors.green : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              state.isReminderActive
                  ? 'Reminder is active (every ${state.selectedInterval} hour${state.selectedInterval > 1 ? 's' : ''})'
                  : 'Reminder is inactive',
              style: TextStyle(
                color: state.isReminderActive ? Colors.green : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, ErrorState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? "",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<WaterReminderCubit>().initializeApp(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}