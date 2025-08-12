import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class UtilFunctions {
  tz.TZDateTime nextInstanceOfTime(DateTime time, Day day) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime sheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (sheduledDate.isBefore(now) || sheduledDate.weekday != day.index + 1) {
      sheduledDate = sheduledDate.add(Duration(days: 1));
    }

    return sheduledDate;
  }
}
