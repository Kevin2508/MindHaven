import 'package:flutter/material.dart';
import 'package:mindhaven/Home/home_page.dart'; // Ensure this matches your project structure

class ExerciseCompletedPage extends StatefulWidget {
  final double durationMinutes; // Pass the duration in minutes

  const ExerciseCompletedPage({super.key, required this.durationMinutes});

  @override
  _ExerciseCompletedPageState createState() => _ExerciseCompletedPageState();
}

class _ExerciseCompletedPageState extends State<ExerciseCompletedPage> {
  late double _totalTime;
  late String _timeUnit;

  @override
  void initState() {
    super.initState();
    _totalTime = widget.durationMinutes;
    _timeUnit = _totalTime >= 60 ? 'H' : 'M';
    if (_timeUnit == 'H') {
      _totalTime = _totalTime / 60; // Convert to hours if >= 60 minutes
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
                  'DURATION: ${_totalTime.toStringAsFixed(2)}$_timeUnit',
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