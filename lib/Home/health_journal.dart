import 'package:flutter/material.dart';
import 'package:mindhaven/Home/home_page.dart'; // Replace with your actual import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindhaven/Home/new_journal_entry.dart'; // Replace with your actual import
import 'package:flutter_animate/flutter_animate.dart';

class HealthJournalPage extends StatefulWidget {
  const HealthJournalPage({super.key});

  @override
  _HealthJournalPageState createState() => _HealthJournalPageState();
}

class _HealthJournalPageState extends State<HealthJournalPage> {
  List<Map<String, dynamic>> _journalData = [];
  int _totalEntriesThisYear = 0;
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadJournalData();
  }

  Future<void> _loadJournalData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final startOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
        final endOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
        final history = await supabase
            .from('journal_entries')
            .select('mood, timestamp, title')
            .eq('user_id', user.id)
            .gte('timestamp', startOfMonth.toIso8601String())
            .lte('timestamp', endOfMonth.toIso8601String())
            .order('timestamp', ascending: false);

        final startOfYear = DateTime(_currentDate.year, 1, 1);
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
    if (averageMood <= 2.0) return Color(0xffd32f2f); // Deep red for negative
    if (averageMood <= 3.0) return Color(0xff8d5524); // Warm brown for neutral
    return Color(0xff4caf50); // Vibrant green for positive
  }

  Gradient _getMoodGradient(double averageMood) {
    if (averageMood <= 2.0) {
      return LinearGradient(
        colors: [Color(0xffd32f2f), Color(0xffd32f2f).withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (averageMood <= 3.0) {
      return LinearGradient(
        colors: [Color(0xff8d5524), Color(0xff8d5524).withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [Color(0xff4caf50), Color(0xff4caf50).withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Map<String, double> _getDailyMoodAverages() {
    final moodAverages = <String, List<int>>{};
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentDate.year, _currentDate.month, i);
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
      averages[date] = moods.isNotEmpty ? moods.reduce((a, b) => a + b) / moods.length : 0.0;
    });
    return averages;
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      _loadJournalData();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      _loadJournalData();
    });
  }

  void _changeYear() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xfff4eee0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Select Year',
            style: TextStyle(color: Color(0xff5e3e2b), fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 200,
            height: 150,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              selectedDate: _currentDate,
              onChanged: (DateTime dateTime) {
                setState(() {
                  _currentDate = DateTime(dateTime.year, _currentDate.month, 1);
                  _loadJournalData();
                });
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Color(0xff5e3e2b))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyMoodAverages = _getDailyMoodAverages();
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff926247), Color(0xff5e3e2b)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          splashRadius: 24,
                          tooltip: 'Back to Home',
                        ),
                        Text(
                          'Health Journal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 2))],
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_totalEntriesThisYear',
                            style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            'of 365 days journaled in ${_currentDate.year}',
                            style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: Offset(0.9, 0.9)),
                  ],
                ),
              ),
              // Calendar Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xfff4eee0),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40), bottom: Radius.circular(40)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -6))],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_left, color: Color(0xff5e3e2b), size: 36),
                              onPressed: _previousMonth,
                              tooltip: 'Previous Month',
                            ),
                            TextButton(
                              onPressed: _changeYear,
                              child: Text(
                                DateFormat('MMMM yyyy').format(_currentDate),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff5e3e2b),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_right, color: Color(0xff5e3e2b), size: 36),
                              onPressed: _nextMonth,
                              tooltip: 'Next Month',
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                        SizedBox(height: 20),
                        Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: daysInMonth,
                            itemBuilder: (context, index) {
                              final day = index + 1;
                              final date = DateTime(_currentDate.year, _currentDate.month, day);
                              final dateString = DateFormat('yyyy-MM-dd').format(date);
                              final averageMood = dailyMoodAverages[dateString] ?? 0.0;
                              final hasEntry = averageMood > 0.0;

                              return GestureDetector(
                                onTap: () {
                                  if (hasEntry) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${DateFormat('MMM d').format(date)}: Mood ${averageMood.toStringAsFixed(1)}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: _getMoodColor(averageMood),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (hasEntry)
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: _getMoodGradient(averageMood),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: hasEntry ? Colors.white : Color(0xff5e3e2b),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (index * 50).ms).scale();
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLegend('Negative', Color(0xffd32f2f)),
                            _buildLegend('Neutral', Color(0xff8d5524)),
                            _buildLegend('Positive', Color(0xff4caf50)),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 16,top: 8),
                child: FloatingActionButton(
                  onPressed: _addNewJournal,
                  backgroundColor: Color(0xfff4eee0),
                  elevation: 8,
                  shape: CircleBorder(),
                  child: Icon(Icons.add, color: Color(0xff5e3e2b), size: 32),
                  tooltip: 'Add New Journal',
                ).animate().scale(duration: 600.ms).then().shakeX(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1))],
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Color(0xff5e3e2b), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}