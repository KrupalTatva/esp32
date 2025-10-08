import 'dart:developer';

import 'package:esp/bloc/cubit/dashboard_cubit.dart';
import 'package:esp/router/AppRouter.dart';
import 'package:esp/screen/auth_wrapper.dart';
import 'package:esp/service/bluetooth_background_worker.dart';
import 'package:esp/service/bluetooth_service.dart';
import 'package:esp/service/database_service.dart';
import 'package:esp/service/water_reminder_worker.dart';
import 'package:esp/service/preference_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'bloc/cubit/auth_cubit.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Background task executed: $task");

    switch (task) {
      case WaterReminderService.waterReminderTask:
        print("task notification");
        return WaterReminderService.showWaterReminderNotification();
      case BackgroundWorker.bleTaskName:
        print("get data");
        return BackgroundWorker.getSensorData();
      default:
        return Future.value(true);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService().initialize();
  await BluetoothService.instance.initialize(isMock: kDebugMode);
  await Workmanager().initialize(
    callbackDispatcher,
  );

  await PrefsService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    BackgroundWorker.stopBackgroundTask();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔄 Lifecycle changed to: $state");
    switch (state) {
      case AppLifecycleState.inactive:
        print("worker tracking ${BluetoothService.instance.isTracking}");
        if (BluetoothService.instance.isTracking) {
          BackgroundWorker.startBackgroundTask();
        }
        break;

      case AppLifecycleState.resumed:
        BackgroundWorker.stopBackgroundTask();
        break;

      default:
        break;
    }
  }

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
