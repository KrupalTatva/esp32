import 'package:esp/component/Color.dart';
import 'package:esp/component/water_bottle_animation.dart';
import 'package:esp/component/water_fill_animation.dart';
import 'package:flutter/material.dart';

import '../model/water_intake_data.dart';

class CalenderView extends StatefulWidget {

  final List<WaterIntakeData> waterIntakeData;
  final double maxIntake;
  const CalenderView({super.key, required this.waterIntakeData, this.maxIntake = 4});

  @override
  State<CalenderView> createState() => _CalenderViewState();
}

class _CalenderViewState extends State<CalenderView> {
  bool isGridView = true;
  DateTime currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return  SizedBox(
      width: double.maxFinite,
      height: 620,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => isGridView = true),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isGridView ? AppColors.primary : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: isGridView ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => isGridView = false),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !isGridView ? AppColors.primary : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    ),
                    child: Icon(
                      Icons.view_list,
                      color: !isGridView ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Month Navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: previousMonth,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 32,
                ),
                Text(
                  '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 32,
                ),
              ],
            ),
          ),

          Expanded(
            child: isGridView ? _buildGridView(widget.maxIntake) : _buildListView(widget.maxIntake),
          ),
        ],
      ),
    );
  }

  double? getWaterIntake(DateTime date) {
    try {
      return widget.waterIntakeData
          .firstWhere((data) =>
      data.date.year == date.year &&
          data.date.month == date.month &&
          data.date.day == date.day)
          .waterLiters;
    } catch (e) {
      return null;
    }
  }

  List<DateTime> getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;

    List<DateTime> days = [];
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  List<DateTime> getCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    List<DateTime> days = [];

    // Add empty days before month starts
    for (int i = 0; i < startWeekday; i++) {
      days.add(firstDay.subtract(Duration(days: startWeekday - i)));
    }

    // Add days of current month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    return days;
  }

  void previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  Widget _buildGridView(double maxIntake) {
    final calendarDays = getCalendarDays(currentMonth);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: calendarDays.length,
              itemBuilder: (context, index) {
                final date = calendarDays[index];
                final isCurrentMonth = date.month == currentMonth.month;
                final waterIntake = getWaterIntake(date);

                return _buildCalendarCell(date, waterIntake, isCurrentMonth, maxIntake);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(DateTime date, double? waterIntake, bool isCurrentMonth, double maxIntake) {
    final fillPercent = waterIntake != null ? (waterIntake / maxIntake).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Water container
          if (waterIntake != null)
            Expanded(
              child: WaterFillAnimation(
                fillPercent: fillPercent,
                waterAmount: waterIntake,
              ),
            )
          else
            Expanded(
              child: Center(),
            ),

          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrentMonth ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(double maxIntake) {
    final daysInMonth = getDaysInMonth(currentMonth);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: daysInMonth.length,
      itemBuilder: (context, index) {
        final date = daysInMonth[index];
        final waterIntake = getWaterIntake(date);

        return _buildListItem(date, waterIntake, maxIntake);
      },
    );
  }

  Widget _buildListItem(DateTime date, double? waterIntake, double maxIntake) {
    final fillPercent = waterIntake != null ? (waterIntake / maxIntake).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Water bottle
          Expanded(
            child: waterIntake != null
                ? WaterBottleAnimation(
              fillPercent: fillPercent,
              waterAmount: waterIntake,
            )
                : Center(
              child: Icon(
                Icons.water_drop_outlined,
                color: Colors.grey.shade300,
                size: 48,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date info
          Column(
            children: [
              Text(
                _getDayName(date.weekday),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_getMonthName(date.month)} ${date.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
