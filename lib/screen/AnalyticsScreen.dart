import 'package:flutter/material.dart';
import '../component/Color.dart';
import '../component/calender_view.dart';
import '../component/water_intake_graph.dart';
import '../model/water_intake_data.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBackground,
        title: const Row(
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
          child: Column(
            children: [
              CalenderView(waterIntakeData: demoWaterData),
              WaterIntakeGraphWidget(data: demoWaterData, maxY: 4,),
            ],
          )
      ),
    );
  }
}
