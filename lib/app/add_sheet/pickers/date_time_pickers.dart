import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

DateTime defaultFutureDateTime() {
  final now = DateTime.now().add(const Duration(hours: 1));
  final nextMinute = ((now.minute / 5).ceil() * 5) % 60;
  final nextHour = nextMinute == 0 ? now.hour + 1 : now.hour;
  return DateTime(
    now.year,
    now.month,
    now.day,
    nextHour,
    nextMinute,
  );
}

Future<DateTime?> pickAdaptiveDateTime(
  BuildContext context, {
  required DateTime initialValue,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialValue,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialValue),
  );
  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

Future<DateTime?> pickCupertinoDatePart(
  BuildContext context, {
  required DateTime initialValue,
}) {
  return _showCupertinoPickerSheet(
    context,
    initialValue: initialValue,
    mode: CupertinoDatePickerMode.date,
  );
}

Future<DateTime?> pickCupertinoTimePart(
  BuildContext context, {
  required DateTime initialValue,
}) {
  return _showCupertinoPickerSheet(
    context,
    initialValue: initialValue,
    mode: CupertinoDatePickerMode.time,
  );
}

Future<DateTime?> _showCupertinoPickerSheet(
  BuildContext context, {
  required DateTime initialValue,
  required CupertinoDatePickerMode mode,
}) {
  var pickedValue = initialValue;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (popupContext) {
      final brightness = Theme.of(context).brightness;
      final backgroundColor = brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : Colors.white;
      return Container(
        height: 320,
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(popupContext).pop(),
                    child: const Text('取消'),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        Navigator.of(popupContext).pop(pickedValue),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: mode,
                use24hFormat: false,
                initialDateTime: initialValue,
                onDateTimeChanged: (value) {
                  pickedValue = value;
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

String formatIosDateLabel(DateTime value) {
  final now = DateTime.now();
  final isToday = value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
  if (isToday) {
    return '今天';
  }
  return '${value.year}年${value.month}月${value.day}日';
}

String formatIosTimeLabel(DateTime value) {
  final period = value.hour < 12 ? '上午' : '下午';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$period $hour:$minute';
}
