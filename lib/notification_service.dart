import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
class KuliahNotificationService {
  static final KuliahNotificationService instance =
  KuliahNotificationService._();
  KuliahNotificationService._();
  final FlutterLocalNotificationsPlugin plugin =
  FlutterLocalNotificationsPlugin();
  static const String channelId = 'kuliah_reminder';
  static const String channelName = 'Pengingat Kuliah';
  Future<void> initialize() async {
    tz.initializeTimeZones();
    final timezoneInfo =
    await FlutterTimezone.getLocalTimezone();
    // flutter_timezone 5.x menggunakan identifier
    // untuk IANA timezone, misalnya Asia/Jakarta.
    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );
    const androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(
      android: androidSettings,
    );
    await plugin.initialize(settings);
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }
  NotificationDetails get notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription:
        'Pengingat jadwal kuliah KuliahKu',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
    );
  }
  Future<void> scheduleAll(
      List<dynamic> schedules,
      ) async {
    await plugin.cancelAll();
    for (final schedule in schedules) {
      await scheduleSchedule(schedule);
    }
  }
  Future<void> scheduleSchedule(
      dynamic schedule,
      ) async {
    final day = schedule.day as int;
    final startParts =
    (schedule.start as String).split(':');
    final hour = int.parse(startParts[0]);
    final minute = int.parse(startParts[1]);
    final now = tz.TZDateTime.now(tz.local);
    var classDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (
    classDate.weekday != day ||
        !classDate.isAfter(now)) {
      classDate = classDate.add(
        const Duration(days: 1),
      );
      classDate = tz.TZDateTime(
        tz.local,
        classDate.year,
        classDate.month,
        classDate.day,
        hour,
        minute,
      );
    }
    final notificationDate =
    classDate.subtract(
      const Duration(minutes: 15),
    );
    final notificationId =
    _notificationId(schedule.id as String);
    await plugin.zonedSchedule(
      notificationId,
      '⏰ Kuliah sebentar lagi',
      '${schedule.subject} • ${schedule.room}',
      notificationDate,
      notificationDetails,
      androidScheduleMode:
      AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
      DateTimeComponents.dayOfWeekAndTime,
      payload: schedule.id as String,
    );
  }
  int _notificationId(String id) {
    return id.codeUnits.fold(
      0,
          (previous, current) =>
      previous * 31 + current,
    ) &
    0x7fffffff;
  }
  Future<void> showTestNotification() async {
    await plugin.show(
      999999,
      'KuliahKu 🔔',
      'Notifikasi KuliahKu sudah aktif!',
      notificationDetails,
    );
  }
}