import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await KuliahNotificationService.instance.initialize();

  runApp(const KuliahKuApp());
}

// ============================================================
// MODEL
// ============================================================

class Schedule {
  final String id;
  final int day;
  final String start;
  final String end;
  final String subject;
  final String room;

  Schedule({
    required this.id,
    required this.day,
    required this.start,
    required this.end,
    required this.subject,
    required this.room,
  });

  String get dayName {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return days[day];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'start': start,
      'end': end,
      'subject': subject,
      'room': room,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      day: map['day'],
      start: map['start'],
      end: map['end'],
      subject: map['subject'],
      room: map['room'],
    );
  }
}

// ============================================================
// STORAGE
// ============================================================

class ScheduleStorage {
  static const String key = 'kuliahku_schedules';

  static Future<List<Schedule>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key);

    if (data == null || data.isEmpty) {
      final defaults = defaultSchedules();
      await save(defaults);
      return defaults;
    }

    return data.map((item) {
      final parts = item.split('|');

      return Schedule(
        id: parts[0],
        day: int.parse(parts[1]),
        start: parts[2],
        end: parts[3],
        subject: parts[4],
        room: parts[5],
      );
    }).toList();
  }

  static Future<void> save(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();

    final data = schedules.map((schedule) {
      return [
        schedule.id,
        schedule.day,
        schedule.start,
        schedule.end,
        schedule.subject,
        schedule.room,
      ].join('|');
    }).toList();

    await prefs.setStringList(key, data);
  }
}

// ============================================================
// DEFAULT SCHEDULE
// ============================================================

List<Schedule> defaultSchedules() {
  return [
    Schedule(
      id: 'mon-uiux',
      day: 1,
      start: '08:40',
      end: '10:55',
      subject: 'User Interface / User Experience Design',
      room: 'LR-01',
    ),
    Schedule(
      id: 'tue-agile',
      day: 2,
      start: '08:40',
      end: '10:55',
      subject:
      'Information System Agile Project Management with DevOps',
      room: 'LR-01',
    ),
    Schedule(
      id: 'tue-ai',
      day: 2,
      start: '13:40',
      end: '15:55',
      subject: 'Artificial Intelligence for Information System',
      room: 'CR-03',
    ),
    Schedule(
      id: 'wed-gov',
      day: 3,
      start: '13:40',
      end: '15:55',
      subject: 'Government Information System',
      room: 'CR-04',
    ),
    Schedule(
      id: 'thu-mobile',
      day: 4,
      start: '08:40',
      end: '10:55',
      subject: 'Mobile Application Development',
      room: 'LR-01',
    ),
    Schedule(
      id: 'thu-stat',
      day: 4,
      start: '13:40',
      end: '15:55',
      subject: 'Probability and Statistics',
      room: 'CR-02',
    ),
    Schedule(
      id: 'fri-security',
      day: 5,
      start: '08:40',
      end: '10:55',
      subject: 'Information System Assurance and Security',
      room: 'CR-04',
    ),
    Schedule(
      id: 'fri-writing',
      day: 5,
      start: '13:40',
      end: '15:55',
      subject: 'Academic Writing and Research Paper',
      room: 'CR-05',
    ),
  ];
}

// ============================================================
// WIDGET UPDATE
// ============================================================

Future<void> updateKuliahKuWidget(
    List<Schedule> schedules,
    ) async {
  if (schedules.isEmpty) {
    await HomeWidget.saveWidgetData<String>(
      'next_subject',
      'Tidak ada jadwal',
    );

    await HomeWidget.saveWidgetData<String>(
      'next_time',
      '-',
    );

    await HomeWidget.saveWidgetData<String>(
      'next_room',
      '',
    );

    await HomeWidget.updateWidget(
      qualifiedAndroidName:
      'com.example.kuliahku.KuliahKuWidgetProvider',
    );

    return;
  }

  final now = DateTime.now();

  final sorted = [...schedules]
    ..sort((a, b) {
      if (a.day != b.day) {
        return a.day.compareTo(b.day);
      }

      return a.start.compareTo(b.start);
    });

  Schedule? next;

  for (final schedule in sorted) {
    if (schedule.day < now.weekday) {
      continue;
    }

    if (schedule.day == now.weekday) {
      final parts = schedule.start.split(':');

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final startMinutes = hour * 60 + minute;
      final currentMinutes = now.hour * 60 + now.minute;

      if (startMinutes <= currentMinutes) {
        continue;
      }
    }

    next = schedule;
    break;
  }

  next ??= sorted.first;

  await HomeWidget.saveWidgetData<String>(
    'next_subject',
    next.subject,
  );

  await HomeWidget.saveWidgetData<String>(
    'next_time',
    '${next.start} - ${next.end}',
  );

  await HomeWidget.saveWidgetData<String>(
    'next_room',
    next.room,
  );

  await HomeWidget.updateWidget(
    qualifiedAndroidName:
    'com.example.kuliahku.KuliahKuWidgetProvider',
  );
}

// ============================================================
// APP
// ============================================================

class KuliahKuApp extends StatelessWidget {
  const KuliahKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KuliahKu',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor:
        const Color(0xFFFFF9FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE889A8),
          brightness: Brightness.light,
        ),
        fontFamily: 'sans',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF9FB),
          foregroundColor: Color(0xFF30272B),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(22),
            ),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// ============================================================
// MAIN NAVIGATION
// ============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  int currentIndex = 0;
  List<Schedule> schedules = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    final result = await ScheduleStorage.load();

    await KuliahNotificationService.instance
        .scheduleAll(result);

    await updateKuliahKuWidget(result);

    if (!mounted) return;

    setState(() {
      schedules = result;
      loading = false;
    });
  }

  Future<void> refreshSchedules() async {
    final result = await ScheduleStorage.load();

    await KuliahNotificationService.instance
        .scheduleAll(result);

    await updateKuliahKuWidget(result);

    if (!mounted) return;

    setState(() {
      schedules = result;
    });
  }

  Future<void> addSchedule() async {
    final result = await Navigator.push<Schedule>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormPage(
          schedules: schedules,
        ),
      ),
    );

    if (result == null) return;

    final updated = [
      ...schedules,
      result,
    ];

    await ScheduleStorage.save(updated);

    await KuliahNotificationService.instance
        .scheduleAll(updated);

    await updateKuliahKuWidget(updated);

    if (!mounted) return;

    setState(() {
      schedules = updated;
    });
  }

  Future<void> editSchedule(
      Schedule schedule,
      ) async {
    final result = await Navigator.push<Schedule>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormPage(
          schedule: schedule,
          schedules: schedules,
        ),
      ),
    );

    if (result == null) return;

    final updated = schedules.map((item) {
      if (item.id == result.id) {
        return result;
      }

      return item;
    }).toList();

    await ScheduleStorage.save(updated);

    await KuliahNotificationService.instance
        .scheduleAll(updated);

    await updateKuliahKuWidget(updated);

    if (!mounted) return;

    setState(() {
      schedules = updated;
    });
  }

  Future<void> deleteSchedule(
      Schedule schedule,
      ) async {
    final updated = schedules
        .where((item) => item.id != schedule.id)
        .toList();

    await ScheduleStorage.save(updated);

    await KuliahNotificationService.instance
        .scheduleAll(updated);

    await updateKuliahKuWidget(updated);

    if (!mounted) return;

    setState(() {
      schedules = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      HomePage(
        schedules: schedules,
        onRefresh: refreshSchedules,
      ),
      WeeklyPage(
        schedules: schedules,
        onEdit: editSchedule,
        onDelete: deleteSchedule,
      ),
      ProfilePage(
        schedules: schedules,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],

      floatingActionButton: currentIndex == 1
          ? FloatingActionButton.extended(
        onPressed: addSchedule,
        backgroundColor:
        const Color(0xFFBE5878),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor:
        const Color(0xFFF9D8E3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
            ),
            selectedIcon: Icon(
              Icons.calendar_month,
            ),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatelessWidget {
  final List<Schedule> schedules;
  final Future<void> Function() onRefresh;

  const HomePage({
    super.key,
    required this.schedules,
    required this.onRefresh,
  });

  Schedule? getNextClass() {
    if (schedules.isEmpty) return null;

    final now = DateTime.now();

    final sorted = [...schedules]
      ..sort((a, b) {
        if (a.day != b.day) {
          return a.day.compareTo(b.day);
        }

        return a.start.compareTo(b.start);
      });

    for (final schedule in sorted) {
      if (schedule.day < now.weekday) {
        continue;
      }

      if (schedule.day == now.weekday) {
        final parts = schedule.start.split(':');

        final minutes =
            int.parse(parts[0]) * 60 +
                int.parse(parts[1]);

        final current =
            now.hour * 60 + now.minute;

        if (minutes <= current) {
          continue;
        }
      }

      return schedule;
    }

    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final nextClass = getNextClass();

    final today = DateTime.now().weekday;

    final todaySchedules = schedules
        .where(
          (schedule) => schedule.day == today,
    )
        .toList()
      ..sort(
            (a, b) => a.start.compareTo(b.start),
      );

    final todayName = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ][today];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            110,
          ),
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KULIAHKU',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color:
                        const Color(0xFFBE5878),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Halo 👋',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF30272B),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF9D8E3),
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFBE5878),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // NEXT CLASS
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE889A8),
                    Color(0xFFD96F94),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE889A8)
                        .withOpacity(0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.20),
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Text(
                          'NEXT CLASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    nextClass?.subject ??
                        'Tidak ada jadwal',
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (nextClass != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${nextClass.dayName} • ${nextClass.start}',
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          nextClass.room,
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jadwal Hari Ini',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF30272B),
                  ),
                ),
                Text(
                  todayName,
                  style: const TextStyle(
                    color: Color(0xFFBE5878),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (todaySchedules.isEmpty)
              Container(
                padding:
                const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(22),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 42,
                      color: Color(0xFFE889A8),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tidak ada kuliah hari ini',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Nikmati hari kamu ✨',
                      style: TextStyle(
                        color: Color(0xFF8D7B82),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...todaySchedules.map(
                    (schedule) => Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: ScheduleCard(
                    schedule: schedule,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCHEDULE CARD
// ============================================================

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const ScheduleCard({
    super.key,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE889A8),
              borderRadius:
              BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subject,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF30272B),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: Color(0xFFBE5878),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${schedule.start} - ${schedule.end}',
                      style: const TextStyle(
                        color: Color(0xFF8D7B82),
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFFBE5878),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      schedule.room,
                      style: const TextStyle(
                        color: Color(0xFF8D7B82),
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WEEKLY PAGE
// ============================================================

class WeeklyPage extends StatelessWidget {
  final List<Schedule> schedules;
  final Future<void> Function(Schedule) onEdit;
  final Future<void> Function(Schedule) onDelete;

  const WeeklyPage({
    super.key,
    required this.schedules,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          110,
        ),
        children: [
          const Text(
            'Jadwal Kuliah',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF30272B),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Atur semua jadwal perkuliahan kamu.',
            style: TextStyle(
              color: Color(0xFF8D7B82),
            ),
          ),

          const SizedBox(height: 25),

          ...List.generate(5, (index) {
            final day = index + 1;

            final daySchedules = schedules
                .where(
                  (schedule) =>
              schedule.day == day,
            )
                .toList()
              ..sort(
                    (a, b) =>
                    a.start.compareTo(b.start),
              );

            final dayName = [
              'Senin',
              'Selasa',
              'Rabu',
              'Kamis',
              'Jumat',
            ][index];

            return Padding(
              padding:
              const EdgeInsets.only(
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF30272B),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (daySchedules.isEmpty)
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                      BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: const Text(
                        'Tidak ada jadwal',
                        style: TextStyle(
                          color:
                          Color(0xFFAAA0A5),
                        ),
                      ),
                    )
                  else
                    ...daySchedules.map(
                          (schedule) => Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: Dismissible(
                          key: ValueKey(
                            schedule.id,
                          ),
                          direction:
                          DismissDirection
                              .endToStart,
                          background: Container(
                            alignment:
                            Alignment
                                .centerRight,
                            padding:
                            const EdgeInsets
                                .only(
                              right: 20,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.redAccent,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .delete_outline,
                              color:
                              Colors.white,
                            ),
                          ),
                          confirmDismiss:
                              (_) async {
                            return await showDialog<
                                bool>(
                              context:
                              context,
                              builder: (_) =>
                                  AlertDialog(
                                    title:
                                    const Text(
                                      'Hapus jadwal?',
                                    ),
                                    content:
                                    Text(
                                      schedule
                                          .subject,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () =>
                                            Navigator
                                                .pop(
                                              context,
                                              false,
                                            ),
                                        child:
                                        const Text(
                                          'Batal',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                            Navigator
                                                .pop(
                                              context,
                                              true,
                                            ),
                                        child:
                                        const Text(
                                          'Hapus',
                                        ),
                                      ),
                                    ],
                                  ),
                            ) ??
                                false;
                          },
                          onDismissed: (_) {
                            onDelete(schedule);
                          },
                          child: InkWell(
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                            onTap: () {
                              onEdit(schedule);
                            },
                            child: ScheduleCard(
                              schedule: schedule,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// FORM PAGE
// ============================================================

class ScheduleFormPage
    extends StatefulWidget {
  final Schedule? schedule;
  final List<Schedule> schedules;

  const ScheduleFormPage({
    super.key,
    this.schedule,
    required this.schedules,
  });

  @override
  State<ScheduleFormPage> createState() =>
      _ScheduleFormPageState();
}

class _ScheduleFormPageState
    extends State<ScheduleFormPage> {
  final subjectController =
  TextEditingController();

  final roomController =
  TextEditingController();

  int selectedDay = 1;

  TimeOfDay startTime =
  const TimeOfDay(
    hour: 8,
    minute: 40,
  );

  TimeOfDay endTime =
  const TimeOfDay(
    hour: 10,
    minute: 55,
  );

  @override
  void initState() {
    super.initState();

    final schedule = widget.schedule;

    if (schedule != null) {
      subjectController.text =
          schedule.subject;

      roomController.text =
          schedule.room;

      selectedDay = schedule.day;

      final start =
      schedule.start.split(':');

      final end =
      schedule.end.split(':');

      startTime = TimeOfDay(
        hour: int.parse(start[0]),
        minute: int.parse(start[1]),
      );

      endTime = TimeOfDay(
        hour: int.parse(end[0]),
        minute: int.parse(end[1]),
      );
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    roomController.dispose();
    super.dispose();
  }

  String formatTime(TimeOfDay time) {
    final hour =
    time.hour.toString().padLeft(2, '0');

    final minute =
    time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> selectStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (result != null) {
      setState(() {
        startTime = result;
      });
    }
  }

  Future<void> selectEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (result != null) {
      setState(() {
        endTime = result;
      });
    }
  }

  void saveSchedule() {
    final subject =
    subjectController.text.trim();

    final room =
    roomController.text.trim();

    if (subject.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nama mata kuliah dan ruangan wajib diisi.',
          ),
        ),
      );

      return;
    }

    final schedule = Schedule(
      id: widget.schedule?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
      day: selectedDay,
      start: formatTime(startTime),
      end: formatTime(endTime),
      subject: subject,
      room: room,
    );

    Navigator.pop(
      context,
      schedule,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.schedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Edit Jadwal'
              : 'Tambah Jadwal',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Mata Kuliah',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: subjectController,
            decoration: InputDecoration(
              hintText:
              'Contoh: Mobile Application Development',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(16),
                borderSide:
                BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Hari',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: selectedDay,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(16),
                borderSide:
                BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 1,
                child: Text('Senin'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('Selasa'),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text('Rabu'),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text('Kamis'),
              ),
              DropdownMenuItem(
                value: 5,
                child: Text('Jumat'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedDay = value;
              });
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Jam',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  selectStartTime,
                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 17,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(16),
                    ),
                  ),
                  child: Text(
                    formatTime(startTime),
                  ),
                ),
              ),

              const Padding(
                padding:
                EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Text('-'),
              ),

              Expanded(
                child: OutlinedButton(
                  onPressed:
                  selectEndTime,
                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 17,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(16),
                    ),
                  ),
                  child: Text(
                    formatTime(endTime),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Ruangan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: roomController,
            decoration: InputDecoration(
              hintText:
              'Contoh: LR-01',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(16),
                borderSide:
                BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: saveSchedule,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFE889A8),
                foregroundColor:
                Colors.white,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
              ),
              child: Text(
                isEdit
                    ? 'Simpan Perubahan'
                    : 'Tambah Jadwal',
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage
    extends StatelessWidget {
  final List<Schedule> schedules;

  const ProfilePage({
    super.key,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          110,
        ),
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF30272B),
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding:
            const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFF9D8E3,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(20),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color:
                    Color(0xFFBE5878),
                  ),
                ),

                const SizedBox(width: 16),

                const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Mahasiswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'KuliahKu',
                      style: TextStyle(
                        color:
                        Color(0xFF8D7B82),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding:
            const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Text(
                        'Total Mata Kuliah',
                        style: TextStyle(
                          color:
                          Color(0xFF8D7B82),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${schedules.length}',
                        style:
                        const TextStyle(
                          fontSize: 25,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 45,
                  color:
                  const Color(
                    0xFFEFE5E9,
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.only(
                      left: 20,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: const [
                        Text(
                          'Semester',
                          style:
                          TextStyle(
                            color:
                            Color(
                              0xFF8D7B82,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Aktif',
                          style:
                          TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(
                              0xFFBE5878,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Tentang',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding:
            const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons
                      .notifications_active_outlined,
                  color:
                  Color(0xFFBE5878),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'KuliahKu akan mengingatkan kamu '
                        '15 menit sebelum jadwal kuliah.',
                    style: TextStyle(
                      color:
                      Color(0xFF6F6268),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await KuliahNotificationService
                    .instance
                    .showTestNotification();
              },
              icon: const Icon(
                Icons.notifications_active,
              ),
              label: const Text(
                'Tes Notifikasi',
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Made by anindyadws',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              '©️ 2026 KuliahKu',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}