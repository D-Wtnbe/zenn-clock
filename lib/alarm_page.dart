import 'package:flutter/material.dart';
import 'alarm_utils.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'alarm_list.dart';
import 'add_alarm_dialog.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  final List<Map<String, dynamic>> _alarms = [];
  int _alarmIdCounter = 1;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
    _initializeNotifications();
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _addAlarm(TimeOfDay picked, String repeatOption, String sound) {
    setState(() {
      _alarms.add({
        'id': _alarmIdCounter,
        'time':
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        'repeatOption': repeatOption,
        'sound': sound,
        'enabled': true,
      });
      _alarms.sort((a, b) => a['time'].compareTo(b['time']));
      _alarmIdCounter++;
    });
    scheduleAlarm(picked, repeatOption, _alarmIdCounter - 1, sound);
  }

  void _deleteAlarm(int index) {
    setState(() {
      int id = _alarms[index]['id'];
      _alarms.removeAt(index);
      Alarm.stop(id);
      _flutterLocalNotificationsPlugin.cancel(id);
    });
  }

  void _editAlarm(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final repeatOption = await showRepeatOptionDialog(context);
      if (repeatOption != null) {
        final selectedSound = await showSelectSoundDialog(context);
        if (selectedSound != null) {
          int id = _alarms[index]['id'];
          setState(() {
            _alarms[index]['time'] =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            _alarms[index]['repeatOption'] = repeatOption;
            _alarms[index]['sound'] = selectedSound;
            _alarms.sort((a, b) => a['time'].compareTo(b['time']));
          });
          await Alarm.stop(id);
          await _flutterLocalNotificationsPlugin.cancel(id);
          await scheduleAlarm(
              picked, repeatOption, _alarms[index]['id'], selectedSound);
        }
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認'),
          content: const Text('このアラームを削除しますか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      _deleteAlarm(index);
    }
  }

  Future<void> _showEditDeleteDialog(BuildContext context, int index) async {
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('アラーム設定'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'edit'),
              child: const Text('編集'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (action == 'edit') {
      _editAlarm(index);
    } else if (action == 'delete') {
      _showDeleteConfirmationDialog(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RiseUp'),
      ),
      body: AlarmList(
        alarms: _alarms,
        onEditDelete: _showEditDeleteDialog,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddAlarmDialog(context, _addAlarm),
        child: const Icon(Icons.add),
      ),
    );
  }
}
