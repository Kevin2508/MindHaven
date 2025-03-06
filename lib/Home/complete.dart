import 'package:flutter/material.dart';
import 'package:mindhaven/Home/home_page.dart'; // Ensure this matches your project structure

class ExerciseCompletedPage extends StatefulWidget {
  final double durationSeconds; // Pass the duration in seconds

  const ExerciseCompletedPage({super.key, required this.durationSeconds});

  @override
  _ExerciseCompletedPageState createState() => _ExerciseCompletedPageState();
}

class _ExerciseCompletedPageState extends State<ExerciseCompletedPage> {
  late String _formattedDuration;

  @override
  void initState() {
    super.initState();
    _formatDuration();
  }

  void _formatDuration() {
    int totalSeconds = widget.durationSeconds.round();
    if (totalSeconds >= 3600) { // 60 minutes = 3600 seconds
      int hours = totalSeconds ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      _formattedDuration = '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}H';
    } else {
      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;
      _formattedDuration = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}M';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff4eee0), Color(0xfffff3e6)], // Light gradient similar to the image
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Exercise Completed!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Task is recorded by Braino.\nYou can continue your activity now!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Duration Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'DURATION: $_formattedDuration',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Brain Character Image
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/excercise.png', // Replace with your asset path
                    width: 280,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Back to Home Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Back to Home',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.home, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}