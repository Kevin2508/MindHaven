import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindhaven/Home/home_page.dart';
import 'package:mindhaven/Home/new_journal_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class SleepTracker {
  static final SleepTracker _instance = SleepTracker._internal();
  factory SleepTracker() => _instance;
  SleepTracker._internal();

  DateTime? _sleepStartTime;
  List<DateTime> _movementEvents = [];
  static const int movementThreshold = 3; // Number of events to confirm waking
  static const Duration movementWindow = Duration(minutes: 5); // 5-minute window
  static const Duration sleepOnsetDelay = Duration(minutes: 30); // 30-minute delay
  static const Duration samplingInterval = Duration(minutes: 5); // Sample every 5 minutes

  BuildContext? _context; // Store context for UI operations

  void initialize(BuildContext context) {
    _context = context; // Store context
    _startBackgroundService();
    _listenToSensors();
  }

  void _startBackgroundService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: false,
      ),
      iosConfiguration: IosConfiguration(),
    );
    await service.startService();
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    final sleepTracker = SleepTracker();
    late Timer _timer;

    _timer = Timer.periodic(SleepTracker.samplingInterval, (timer) async {
      await sleepTracker._checkSleepState();
    });

    service.on('stopService').listen((event) {
      _timer.cancel();
    });
  }

  void _listenToSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      final acceleration = event.x.abs() + event.y.abs() + event.z.abs();
      if (acceleration > 2.0) { // Threshold for significant movement
        _movementEvents.add(DateTime.now());
        _cleanOldEvents();
        _checkWakeUp();
      }
    });
  }

  void _cleanOldEvents() {
    _movementEvents.removeWhere((event) =>
    DateTime.now().difference(event) > SleepTracker.movementWindow);
  }

  Future<void> _checkSleepState() async {
    if (_sleepStartTime == null) {
      if (_movementEvents.isEmpty) {
        await Future.delayed(SleepTracker.sleepOnsetDelay, () {
          if (_movementEvents.isEmpty) {
            _sleepStartTime = DateTime.now();
            _saveSleepStart();
          }
        });
      }
    } else {
      _checkWakeUp();
    }
  }

  void _checkWakeUp() {
    if (_sleepStartTime != null && _movementEvents.length >= SleepTracker.movementThreshold) {
      final sleepEndTime = DateTime.now();
      final duration = sleepEndTime.difference(_sleepStartTime!).inHours +
          sleepEndTime.difference(_sleepStartTime!).inMinutes / 60;
      _saveSleepEnd(duration);
      _sleepStartTime = null;
      _movementEvents.clear();
      if (_context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptSleepQuality(duration, _context!);
        });
      }
    }
  }

  Future<void> _saveSleepStart() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }
    await supabase.from('sleep_logs').insert({
      'user_id': userId,
      'start_time': _sleepStartTime!.toIso8601String(),
      'end_time': null,
    });
  }

  Future<void> _saveSleepEnd(double duration) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }
    final logs = await supabase
        .from('sleep_logs')
        .select('id')
        .eq('user_id', userId)
        .filter('end_time', 'is', null) // Workaround for .is_() error
        .order('start_time', ascending: false)
        .limit(1);
    if (logs.isNotEmpty) {
      await supabase.from('sleep_logs').update({
        'end_time': DateTime.now().toIso8601String(),
        'duration_hours': duration,
      }).eq('id', logs.first['id']);
    }
  }

  Future<void> _saveSleepQuality(String quality, double duration) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }
    final logs = await supabase
        .from('sleep_logs')
        .select('id')
        .eq('user_id', userId)
        .filter('end_time', 'is', null) // Workaround for .is_() error
        .order('start_time', ascending: false)
        .limit(1);
    if (logs.isNotEmpty) {
      await supabase.from('sleep_logs').update({
        'quality': quality,
      }).eq('id', logs.first['id']);
    }
  }

  void _promptSleepQuality(double duration, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('How was your sleep?'),
        content: DropdownButton<String>(
          value: 'Good', // Default value
          hint: const Text('Select Quality'),
          items: ['Worst', 'Poor', 'Fair', 'Good', 'Excellent']
              .map((String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          ))
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _saveSleepQuality(newValue, duration);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}

class SleepDashboard extends StatelessWidget {
  final double? lastSleepDuration;
  final String? lastSleepQuality;

  const SleepDashboard({super.key, this.lastSleepDuration, this.lastSleepQuality});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Night: ${lastSleepDuration?.toStringAsFixed(1) ?? '0.0'}h, Quality: ${lastSleepQuality ?? 'N/A'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class HealthJournalPage extends StatefulWidget {
  const HealthJournalPage({super.key});

  @override
  _HealthJournalPageState createState() => _HealthJournalPageState();
}

class _HealthJournalPageState extends State<HealthJournalPage> {
  List<Map<String, dynamic>> _journalData = [];
  int _totalEntriesThisYear = 0;
  SleepTracker _sleepTracker = SleepTracker();
  double? _lastSleepDuration;
  String? _lastSleepQuality;

  @override
  void initState() {
    super.initState();
    _sleepTracker.initialize(context); // Pass context
    _loadJournalData();
    _loadLatestSleepLog();
  }

  Future<void> _loadJournalData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));

        final history = await supabase
            .from('journal_entries')
            .select('mood, timestamp, title')
            .eq('user_id', user.id)
            .gte('timestamp', thirtyDaysAgo.toIso8601String())
            .order('timestamp', ascending: false);

        final startOfYear = DateTime(now.year, 1, 1);
        final yearEntries = await supabase
            .from('journal_entries')
            .select('timestamp')
            .eq('user_id', user.id)
            .gte('timestamp', startOfYear.toIso8601String());

        final uniqueDays = <String>{};
        for (var entry in yearEntries) {
          final date = DateTime.parse(entry['timestamp'] as String);
          uniqueDays.add(DateFormat('yyyy-MM-dd').format(date));
        }

        setState(() {
          _journalData = List<Map<String, dynamic>>.from(history);
          _totalEntriesThisYear = uniqueDays.length;
        });
      }
    } catch (e) {
      setState(() {
        _journalData = [];
        _totalEntriesThisYear = 0;
      });
    }
  }

  Future<void> _loadLatestSleepLog() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }

    final logs = await supabase
        .from('sleep_logs')
        .select('duration_hours, quality')
        .eq('user_id', userId)
        .order('end_time', ascending: false)
        .limit(1);

    if (logs.isNotEmpty) {
      setState(() {
        _lastSleepDuration = logs.first['duration_hours'] as double?;
        _lastSleepQuality = logs.first['quality'] as String?;
      });
    }
  }

  void _addNewJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewJournalEntryPage()),
    ).then((_) => _loadJournalData());
  }

  int _getMoodValue(String mood) {
    switch (mood) {
      case 'Sad':
        return 1;
      case 'Angry':
        return 2;
      case 'Neutral':
        return 3;
      case 'Happy':
        return 4;
      case 'Very Happy':
        return 5;
      default:
        return 3;
    }
  }

  Color _getMoodColor(double averageMood) {
    if (averageMood < 2) {
      return Colors.red;
    } else if (averageMood < 3) {
      return Colors.orange;
    } else if (averageMood < 4) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Map<String, double> _getDailyMoodAverages() {
    final moodAverages = <String, List<int>>{};
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      moodAverages[dateString] = [];
    }

    for (var entry in _journalData) {
      final timestamp = DateTime.parse(entry['timestamp'] as String);
      final dateString = DateFormat('yyyy-MM-dd').format(timestamp);
      if (moodAverages.containsKey(dateString)) {
        moodAverages[dateString]!.add(_getMoodValue(entry['mood'] as String));
      }
    }

    final averages = <String, double>{};
    moodAverages.forEach((date, moods) {
      if (moods.isNotEmpty) {
        averages[date] = moods.reduce((a, b) => a + b) / moods.length;
      } else {
        averages[date] = 3.0;
      }
    });

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    final dailyMoodAverages = _getDailyMoodAverages();

    return Scaffold(
      backgroundColor: const Color(0xff926247),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                      ),
                      const Text(
                        'Health Journal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '$_totalEntriesThisYear/365',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Journals this year. Keep it Up!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _addNewJournal,
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Journal History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: 30,
                          itemBuilder: (context, index) {
                            final now = DateTime.now();
                            final date = now.subtract(Duration(days: 29 - index));
                            final dateString = DateFormat('yyyy-MM-dd').format(date);
                            final averageMood = dailyMoodAverages[dateString] ?? 3.0;
                            return Container(
                              decoration: BoxDecoration(
                                color: _getMoodColor(averageMood),
                                shape: BoxShape.circle,
                              ),
                              width: 30,
                              height: 30,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Text('Negative', style: TextStyle(color: Colors.orange)),
                          Text('Neutral', style: TextStyle(color: Color(0xff926247))),
                          Text('Positive', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SleepDashboard(
                        lastSleepDuration: _lastSleepDuration,
                        lastSleepQuality: _lastSleepQuality,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFooterButton(Icons.home, true),
                  _buildFooterButton(Icons.message, false),
                  _buildFooterButton(Icons.favorite, false),
                  _buildFooterButton(Icons.person, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(IconData icon, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: Icon(icon, size: 30, color: isActive ? Colors.blue : Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}