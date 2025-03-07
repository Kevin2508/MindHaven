import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mindhaven/Home/mindfulhours.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindhaven/Home/home_page.dart'; // Ensure this matches your project structure
import 'package:mindhaven/Home/breathing.dart';
import 'package:mindhaven/Home/complete.dart'; // Import the new page

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  double _totalTime = 0.00; // Total time in minutes
  String _timeUnit = 'M'; // Default to minutes ('M' or 'H')

  // List of audios with file paths (static playlist)
  final List<Map<String, dynamic>> _audioList = [
    {'title': 'Calm Ocean Waves', 'file': 'audios/Calm Ocean Waves.mp3'},
    {'title': 'Forest Serenity', 'file': 'audios/Forest Serenity.mp3'},
    {'title': 'Gentle Rain', 'file': 'audios/Gentle Rain.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTotalTime();
  }

  Future<void> _loadTotalTime() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final history = await supabase
            .from('mindful_history')
            .select('duration')
            .eq('user_id', user.id)
            .eq('activity_type', 'audio');

        double totalMinutes = 0.0;
        for (var entry in history) {
          totalMinutes += (entry['duration'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
          _totalTime = totalMinutes;
          _timeUnit = totalMinutes >= 60 ? 'H' : 'M';
          if (_timeUnit == 'H') {
            _totalTime = totalMinutes / 60; // Convert to hours if >= 60 minutes
          }
        });
        print('Loaded total time: $_totalTime $_timeUnit');
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error loading total time: $e');
      setState(() {
        _totalTime = 0.00;
        _timeUnit = 'M';
      });
    }
  }

  void _playAudio(Map<String, dynamic> entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StressReliefPage(audioTitle: entry['title'], audioFile: entry['file']),
      ),
    );
    // Reload total time after returning from StressReliefPage
    await _loadTotalTime();
  }

  void _goToHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _goToBreathingExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BreathingExercisePage()),
    );
    // Reload total time after returning from BreathingExercisePage
    await _loadTotalTime();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHomePage();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff4eee0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Exercise',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track your mindful activities',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                // Section 1: Breathing Exercise Button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _goToBreathingExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9BB068),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Complete Your Breathing Exercise',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Section 2: Total Time Duration
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xff878e96),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Time Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${_totalTime.toStringAsFixed(2)}$_timeUnit',
                              style: const TextStyle(
                                fontSize: 70,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeUnit == 'M' ? 'Mindful Minutes' : 'Mindful Hours',
                              style: const TextStyle(
                                fontSize: 34,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Section 3: Playlist
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Playlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: _audioList.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ElevatedButton(
                              onPressed: () => _playAudio(entry),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.all(12.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry['title'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.play_arrow,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}