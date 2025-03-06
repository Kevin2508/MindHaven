import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:mindhaven/Home/home_page.dart'; // Ensure this matches your project structure
import 'package:mindhaven/Home/complete.dart'; // Import the new page

class BreathingExercisePage extends StatefulWidget {
  const BreathingExercisePage({super.key});

  @override
  _BreathingExercisePageState createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage> {
  int _userSetMinutes = 5; // Default duration: 5 minutes
  int _userSetSeconds = 0; // Default seconds
  int _remainingSeconds = 300; // Total remaining time in seconds (default 5:00)
  Timer? _timer; // Countdown timer
  bool _isRunning = false;
  bool _hasStarted = false; // Flag to track if timer has started
  DateTime? _startTime; // Track the exact start time
  TextEditingController _minutesController = TextEditingController(text: '5');
  TextEditingController _secondsController = TextEditingController(text: '00');
  VideoPlayerController? _videoController; // Video player controller

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/breathing_background.mp4')
      ..initialize().then((_) {
        setState(() {}); // Update UI when video is ready
        _videoController!.setLooping(true); // Set video to loop
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.pause(); // Ensure video stops
    _videoController?.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _saveCompletedTime(); // Save time when exiting
    super.dispose();
  }

  void _startTimer() {
    if (!_isRunning) {
      int minutes = int.tryParse(_minutesController.text) ?? 0;
      int seconds = int.tryParse(_secondsController.text) ?? 0;
      int totalSeconds = (minutes * 60) + seconds;

      // Cap at 60 minutes (3600 seconds)
      if (totalSeconds > 3600) {
        totalSeconds = 3600;
        minutes = 60;
        seconds = 0;
        _minutesController.text = '60';
        _secondsController.text = '00';
      } else if (totalSeconds <= 0) {
        totalSeconds = 60; // Minimum 1 minute
        minutes = 1;
        seconds = 0;
        _minutesController.text = '1';
        _secondsController.text = '00';
      }

      _remainingSeconds = totalSeconds;
      _saveSetDuration(totalSeconds / 60.0); // Save to Supabase in minutes

      setState(() {
        _isRunning = true;
        _hasStarted = true; // Mark that the timer has started
        _startTime = DateTime.now(); // Record start time
      });

      // Start video playback
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController!.play();
      } else {
        print('Video controller not initialized');
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _stopTimer();
          }
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _videoController?.pause(); // Stop video playback
    setState(() {
      _isRunning = false;
      // Update text fields to reflect where the timer stopped
      _minutesController.text = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
      _secondsController.text = (_remainingSeconds % 60).toString().padLeft(2, '0');
    });
    _saveCompletedTime(); // Save completed time when timer stops, but don’t navigate
  }

  void _completeExercise() {
    if (_startTime != null) {
      int elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseCompletedPage(durationSeconds: elapsedSeconds.toDouble()),
        ),
      );
    }
  }

  Future<void> _saveSetDuration(double durationInMinutes) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('breathing_settings').upsert({
          'user_id': user.id,
          'set_duration': durationInMinutes, // Store in minutes
          'timestamp': DateTime.now().toIso8601String(),
        });
        print('Saved set duration: $durationInMinutes minutes');
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error saving set duration: $e');
    }
  }

  Future<void> _saveCompletedTime() async {
    if (_startTime != null) {
      int elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      double completedMinutes = elapsedSeconds / 60.0;

      if (completedMinutes > 0) {
        try {
          final supabase = Supabase.instance.client;
          final user = supabase.auth.currentUser;
          if (user != null) {
            await supabase.from('mindful_history').insert({
              'user_id': user.id,
              'activity_name': 'Breathing Exercise',
              'duration': completedMinutes, // Store in minutes
              'activity_type': 'breathing',
              'timestamp': DateTime.now().toIso8601String(),
            });
            print('Saved completed time: $completedMinutes minutes');
          } else {
            print('No user logged in');
          }
        } catch (e) {
          print('Error saving completed time: $e');
        }
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _goToHomePage() {
    _stopTimer(); // Stop timer and video, save time before navigating
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHomePage();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Video background
            if (_videoController != null && _videoController!.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover, // Fit video to screen
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xffA18FFF), // Fallback background if video fails
              ),
            // Foreground content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 270,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Breathing Exercise',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_isRunning) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _minutesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _secondsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 70,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                  Text(
                    _isRunning
                        ? _formatTime(_remainingSeconds)
                        : _formatTime(
                        (int.tryParse(_minutesController.text) ?? 0) * 60 +
                            (int.tryParse(_secondsController.text) ?? 0)),
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 310),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isRunning ? _stopTimer : _startTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            _isRunning ? 'Stop' : 'Start',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        if (!_isRunning && _hasStarted) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _completeExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            ),
                            child: const Text(
                              'Complete Exercise',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}