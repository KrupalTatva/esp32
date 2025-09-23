import 'package:esp/bloc/cubit/dashboard_cubit.dart';
import 'package:esp/router/AppRouter.dart';
import 'package:esp/screen/auth_wrapper.dart';
import 'package:esp/service/WaterReminderService.dart';
import 'package:esp/service/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'bloc/cubit/auth_cubit.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Background task executed: $task");

    switch (task) {
      case 'waterReminderTask':
        print("task notification");
        return WaterReminderService.showWaterReminderNotification();
      default:
        return Future.value(true);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await PrefsService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: AuthWrapper(),
    );
  }
}
