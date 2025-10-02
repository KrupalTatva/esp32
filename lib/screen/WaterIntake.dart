import 'package:esp/component/water_intake_graph.dart';
import 'package:esp/model/water_intake_data.dart';
import 'package:flutter/material.dart';

class WaterCalendarPage extends StatefulWidget {
  const WaterCalendarPage({super.key});

  @override
  State<WaterCalendarPage> createState() => _WaterCalendarPageState();
}

class _WaterCalendarPageState extends State<WaterCalendarPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WaterIntakeGraphWidget(data: demoWaterData));
  }
}