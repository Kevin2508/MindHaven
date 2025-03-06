

import 'package:flutter/material.dart';
import 'package:mindhaven/Home/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindhaven/Home/new_journal_entry.dart';

class HealthJournalPage extends StatefulWidget {
  const HealthJournalPage({super.key});

  @override
  _HealthJournalPageState createState() => _HealthJournalPageState();
}

class _HealthJournalPageState extends State<HealthJournalPage> {
  List<Map<String, dynamic>> _journalData = [];
  int _totalEntriesThisYear = 0;

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
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));

        // Load last 30 days entries for mood visualization
        final history = await supabase
            .from('journal_entries')
            .select('mood, timestamp, title')
            .eq('user_id', user.id)
            .gte('timestamp', thirtyDaysAgo.toIso8601String())
            .order('timestamp', ascending: false);

        // Get all entries for this year
        final startOfYear = DateTime(now.year, 1, 1);
        final yearEntries = await supabase
            .from('journal_entries')
            .select('timestamp')
            .eq('user_id', user.id)
            .gte('timestamp', startOfYear.toIso8601String());

        // Count unique days with entries
        final uniqueDays = <String>{};
        for (var entry in yearEntries) {
          final date = DateTime.parse(entry['timestamp'] as String);
          uniqueDays.add(DateFormat('yyyy-MM-dd').format(date));
        }

        setState(() {
          _journalData = List<Map<String, dynamic>>.from(history);
          _totalEntriesThisYear = uniqueDays.length; // Number of unique days
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

  // Map mood to numerical value for averaging
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
        return 3; // Default to Neutral
    }
  }

  // Get color based on average mood value
  Color _getMoodColor(double averageMood) {
    if (averageMood <= 2.0) return Colors.orange; // Negative
    if (averageMood <= 3.0) return Color(0xff926247); // Neutral
    return Colors.green[300]!; // Positive
  }

  // Calculate average mood for each day in the last 30 days
  Map<String, double> _getDailyMoodAverages() {
    final moodAverages = <String, List<int>>{};
    final now = DateTime.now();

    // Initialize 30 days with empty lists
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      moodAverages[dateString] = [];
    }

    // Populate mood values by day
    for (var entry in _journalData) {
      final timestamp = DateTime.parse(entry['timestamp'] as String);
      final dateString = DateFormat('yyyy-MM-dd').format(timestamp);
      if (moodAverages.containsKey(dateString)) {
        moodAverages[dateString]!.add(_getMoodValue(entry['mood'] as String));
      }
    }

    // Calculate averages
    final averages = <String, double>{};
    moodAverages.forEach((date, moods) {
      if (moods.isNotEmpty) {
        averages[date] = moods.reduce((a, b) => a + b) / moods.length;
      } else {
        averages[date] = 3.0; // Default to Neutral if no entries
      }
    });

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    final dailyMoodAverages = _getDailyMoodAverages();

    return Scaffold(
      backgroundColor: const Color(0xff926247), // Brown background
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: (){
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },

                        // You can implement back navigation if needed
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
            // Journal History Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xfff4eee0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16,),
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
                            final date = now.subtract(Duration(days: 29 - index)); // Reverse order for newest first
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
                          Text('Neutral', style: TextStyle(color: Colors.brown)),
                          Text('Positive', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer

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