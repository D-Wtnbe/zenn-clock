import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;

Future<void> scheduleAlarm(
    TimeOfDay time, String repeatOption, int id, String sound) async {
  final now = DateTime.now();

  if (repeatOption == 'none') {
    DateTime alarmDateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (alarmDateTime.isBefore(now)) {
      alarmDateTime = alarmDateTime.add(const Duration(days: 1));
    }
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: alarmDateTime,
        assetAudioPath: sound,
        notificationSettings: const NotificationSettings(
          title: 'アラーム',
          body: '時間です！',
        ),
      ),
    );
  } else if (repeatOption == 'daily') {
    DateTime alarmDateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (alarmDateTime.isBefore(now)) {
      alarmDateTime = alarmDateTime.add(const Duration(days: 1));
    }
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: alarmDateTime,
        assetAudioPath: sound,
        notificationSettings: const NotificationSettings(
          title: 'アラーム',
          body: '時間です！',
        ),
        vibrate: true,
        fadeDuration: 10.0,
      ),
    );
  } else {
    final days = repeatOption.split(',');
    final excludeDays = days
        .where((day) => day.startsWith('exclude_'))
        .map((day) => day.replaceFirst('exclude_', ''))
        .toList();
    final includeDays =
        days.where((day) => !day.startsWith('exclude_')).toList();

    final excludeHolidays = days.contains('exclude_holidays');

    for (final day in includeDays) {
      final dayIndex =
          ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].indexOf(day);
      DateTime alarmDateTime =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      // 次の指定された曜日になるまで1日ずつ加算
      while (alarmDateTime.weekday != dayIndex + 1 ||
          excludeDays.contains([
            'Sun',
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat'
          ][alarmDateTime.weekday - 1]) ||
          (excludeHolidays && holiday_jp.isHoliday(alarmDateTime))) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }
      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 7));
      }
      // await Alarm.set(
      //   alarmSettings: AlarmSettings(
      //     id: id,
      //     dateTime: alarmDateTime,
      //     assetAudioPath: sound,
      //     loopAudio: true,
      //     vibrate: true,
      //     fadeDuration: 10.0,
      //     notificationTitle: 'アラーム',
      //     notificationBody: '時間です！',
      //     enableNotificationOnKill: true,
      //   ),
      // );
    }
  }
}

Future<void> stopAlarm(int id) async {
  await Alarm.stop(id);
}
