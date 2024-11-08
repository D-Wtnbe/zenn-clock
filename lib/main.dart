import 'package:flutter/material.dart';
import 'alarm_page.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:alarm/alarm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(currentTimeZone));
  await Alarm.init();
  await loadAssets();
  runApp(const MainApp());
}

Future<void> loadAssets() async {
  await Future.wait([
    rootBundle.load('assets/sounds/sound1.mp3'),
    rootBundle.load('assets/sounds/sound2.mp3'),
    rootBundle.load('assets/sounds/sound3.mp3'),
  ]);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const AlarmPage(),
    );
  }
}
