import 'package:flutter/material.dart';
import 'alarm_utils.dart';

class AlarmList extends StatelessWidget {
  final List<Map<String, dynamic>> alarms;
  final Function(BuildContext, int) onEditDelete;

  const AlarmList({
    super.key,
    required this.alarms,
    required this.onEditDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return GestureDetector(
          onTap: () => onEditDelete(context, index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm['time'],
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      alarm['repeatOption'] == 'none'
                          ? '繰り返しなし'
                          : alarm['repeatOption'] == 'daily'
                              ? '毎日'
                              : (alarm['repeatOption'] as String)
                                  .split(',')
                                  .join(', '),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'サウンド: ${alarm['sound']}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Switch(
                      value: alarm['enabled'],
                      onChanged: (bool value) {
                        if (value) {
                          scheduleAlarm(
                            TimeOfDay(
                              hour: int.parse(alarm['time'].split(':')[0]),
                              minute: int.parse(alarm['time'].split(':')[1]),
                            ),
                            alarm['repeatOption'],
                            alarm['id'],
                            alarm['sound'],
                          );
                        } else {
                          stopAlarm(alarm['id']);
                        }
                        alarm['enabled'] = value;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
