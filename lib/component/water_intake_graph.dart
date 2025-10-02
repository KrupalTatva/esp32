import 'package:esp/component/Color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../model/water_intake_data.dart';

class WaterIntakeGraphWidget extends StatefulWidget {
  final List<WaterIntakeData> data;
  final double height;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double maxY;

  const WaterIntakeGraphWidget({
    super.key,
    required this.data,
    this.height = 350,
    this.primaryColor,
    this.backgroundColor,
    this.maxY = 4,
  });

  @override
  State<WaterIntakeGraphWidget> createState() => _WaterIntakeGraphWidgetState();
}

class _WaterIntakeGraphWidgetState extends State<WaterIntakeGraphWidget> {
  bool isWeekView = true;

  // Color get primaryColor => widget.primaryColor ?? Colors.blue.shade400;
  // Color get bgColor => widget.backgroundColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildToggleButton('Week', isWeekView),
                  _buildToggleButton('Month', !isWeekView),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          height: 280,
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isWeekView ? _buildWeekChart(widget.maxY) : _buildMonthChart(widget.maxY),
        )

      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => isWeekView = text == 'Week'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color, {bool isPercentage = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPercentage
                  ? '${value.toStringAsFixed(0)}%'
                  : '${value.toStringAsFixed(1)}L',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekChart(double maxY) {
    final weekData = _getWeekData();

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return LineTooltipItem(
                  '${days[spot.x.toInt()]}\n${spot.y.toStringAsFixed(1)} L',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}L',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: weekData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.4,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: AppColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Goal line
          LineChartBarData(
            spots: List.generate(7, (i) => FlSpot(i.toDouble(), 2.5)),
            isCurved: false,
            color: Colors.green.shade300.withOpacity(0.6),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(double maxInt) {
    final monthData = _getMonthData();

    return LineChart(
      LineChartData(
        maxY: maxInt,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Day ${spot.x.toInt()}\n${spot.y.toStringAsFixed(1)} L',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}L',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: monthData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble() + 1, entry.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Goal line
          LineChartBarData(
            spots: List.generate(
              monthData.length,
                  (i) => FlSpot(i.toDouble() + 1, 2.5),
            ),
            isCurved: false,
            color: Colors.green.shade300.withOpacity(0.6),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  List<double> _getWeekData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    List<double> weekData = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final intake = widget.data.firstWhere(
            (d) => d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
        orElse: () => WaterIntakeData(date: date, waterLiters: 0),
      ).waterLiters;
      weekData[i] = intake;
    }

    return weekData;
  }

  List<double> _getMonthData() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    List<double> monthData = [];

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      final intake = widget.data.firstWhere(
            (d) => d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
        orElse: () => WaterIntakeData(date: date, waterLiters: 0),
      ).waterLiters;
      monthData.add(intake);
    }

    return monthData;
  }

  double _calculateAverage() {
    if (widget.data.isEmpty) return 0;
    final total = widget.data.fold(0.0, (sum, item) => sum + item.waterLiters);
    return total / widget.data.length;
  }

  double _calculateTotal() {
    return widget.data.fold(0.0, (sum, item) => sum + item.waterLiters);
  }

  double _calculateGoalPercentage() {
    const dailyGoal = 2.5;
    if (widget.data.isEmpty) return 0;
    final average = _calculateAverage();
    return (average / dailyGoal) * 100;
  }
}