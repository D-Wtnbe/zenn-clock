import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

Future<void> showAddAlarmDialog(
    BuildContext context, Function(TimeOfDay, String, String) addAlarm) async {
  final timeController = TextEditingController();
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      bool isTimeSelected = false;
      String repeatOption = 'none';
      String selectedSound = 'assets/sounds/sound1.mp3'; // 修正
      final selectedDays = <String>{};
      final excludedDays = <String>{};

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('アラーム追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '時間を選択',
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        timeController.text =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        isTimeSelected = true;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('繰り返し:'),
                _buildRepeatOptionRadio(
                    '繰り返しなし', 'none', repeatOption, setState),
                _buildRepeatOptionRadio('毎日', 'daily', repeatOption, setState),
                _buildRepeatOptionRadio('曜日指定', 'weekly', repeatOption,
                    setState, context, selectedDays),
                if (repeatOption == 'weekly' && selectedDays.isNotEmpty) ...[
                  const Text('繰り返し曜日:'),
                  Text(selectedDays.join(', ')),
                ],
                const Divider(),
                TextButton(
                  onPressed: () async {
                    final excludeDays = await _selectExcludeDays(context);
                    if (excludeDays != null) {
                      setState(() {
                        excludedDays.clear();
                        excludedDays.addAll(excludeDays);
                      });
                    }
                  },
                  child: const Text('除外する曜日を設定'),
                ),
                if (excludedDays.isNotEmpty) ...[
                  const Text('除外する曜日:'),
                  Text(excludedDays.join(', ')),
                ],
                CheckboxListTile(
                  title: const Text('日本の祝日を除外'),
                  value: excludedDays.contains('exclude_holidays'),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        excludedDays.add('exclude_holidays');
                      } else {
                        excludedDays.remove('exclude_holidays');
                      }
                    });
                  },
                ),
                const Divider(),
                const Text('サウンド:'),
                DropdownButton<String>(
                  value: selectedSound,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSound = newValue!;
                    });
                  },
                  items: <String>[
                    'assets/sounds/sound1.mp3',
                    'assets/sounds/sound2.mp3',
                    'assets/sounds/sound3.mp3'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.split('/').last),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: isTimeSelected
                    ? () {
                        setState(() {
                          final result = {
                            'time': timeController.text,
                            'repeatOption': repeatOption == 'weekly'
                                ? (selectedDays.toList()
                                  ..addAll(
                                      excludedDays.map((e) => 'exclude_$e')))
                                : repeatOption,
                            'sound': selectedSound,
                          };
                          Navigator.pop(context, result);
                        });
                      }
                    : null,
                child: const Text('追加'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != null && result['time'] != null) {
    final timeParts = result['time'].split(':');
    final picked = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    final repeatOption = result['repeatOption'] is List
        ? (result['repeatOption'] as List).join(',')
        : result['repeatOption'];
    final sound = result['sound'];
    addAlarm(picked, repeatOption, sound);
  }
}

Future<String?> showRepeatOptionDialog(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('繰り返し設定'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'none'),
            child: const Text('繰り返しなし'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'daily'),
            child: const Text('毎日'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              final days = await _selectDays(context);
              if (days != null) {
                final excludeDays = await _selectExcludeDays(context);
                Navigator.pop(
                    context,
                    days.join(',') +
                        (excludeDays != null
                            ? ',${excludeDays.join(',')}'
                            : ''));
              } else {
                Navigator.pop(context, null);
              }
            },
            child: const Text('曜日指定'),
          ),
        ],
      );
    },
  );
}

Future<String?> showSelectSoundDialog(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'wav'],
  );
  if (result != null && result.files.isNotEmpty) {
    return result.files.single.path;
  }
  return null;
}

Widget _buildRepeatOptionRadio(
    String title, String value, String groupValue, StateSetter setState,
    [BuildContext? context, Set<String>? selectedDays]) {
  return RadioListTile<String>(
    title: Text(title),
    value: value,
    groupValue: groupValue,
    onChanged: (String? newValue) async {
      setState(() {
        groupValue = newValue!;
      });
      if (newValue == 'weekly' && context != null && selectedDays != null) {
        final days = await _selectDays(context);
        if (days != null) {
          setState(() {
            selectedDays.clear();
            selectedDays.addAll(days);
          });
        }
      }
    },
  );
}

Future<List<String>?> _selectDays(BuildContext context) async {
  return await _selectOptions(
      context, 'Select Days', ['日', '月', '火', '水', '木', '金', '土']);
}

Future<List<String>?> _selectExcludeDays(BuildContext context) async {
  return await _selectOptions(context, 'Exclude Days',
      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'exclude_holidays']);
}

Future<List<String>?> _selectOptions(
    BuildContext context, String title, List<String> options) async {
  final selected = <String>{};
  return await showDialog<List<String>>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: selected.contains(option),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selected.toList()),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
