import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  int _currentScore = 0; // Initial score will be calculated
  final List<Map<String, dynamic>> _mentalScoreHistory = [
    {'date': 'SEP 12', 'mood': 'Anxious, Depressed', 'score': 0, 'recommendation': 'Please do 25m Mindfulness.'},
    {'date': 'SEP 11', 'mood': 'Very Happy', 'score': 0, 'recommendation': 'No Recommendation.'},
  ];

  @override
  void initState() {
    super.initState();
    _calculateInitialScore();
  }

  Future<void> _calculateInitialScore() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final responses = await supabase
            .from('questionnaire_responses')
            .select('question_number, answer')
            .eq('user_id', user.id);

        if (responses.isEmpty) {
          setState(() {
            _currentScore = 0;
          });
          return;
        }

        int totalScore = 0;
        for (var response in responses) {
          final questionNumber = response['question_number'] as int;
          final answer = response['answer'] as String;
          totalScore += _calculateQuestionScore(questionNumber, answer);
        }
        // Normalize score to 0-100 and round to the nearest integer
        _currentScore = ((totalScore / 70) * 100).round();
        setState(() {});
      }
    } catch (e) {
      print('Error calculating score: $e');
      setState(() {
        _currentScore = 0;
      });
    }
  }

  int _calculateQuestionScore(int questionNumber, String answer) {
    // Define scoring logic (0-10 per question, adjust weights as needed)
    switch (questionNumber) {
      case 3: // How often do you struggle with anxious thoughts?
        switch (answer) {
          case 'Rarely': return 10;
          case 'Sometimes': return 7;
          case 'Often': return 4;
          case 'Always': return 1;
          default: return 0;
        }
      case 4: // Trouble sleeping?
        switch (answer) {
          case 'No': return 10;
          case 'Sometimes': return 6;
          case 'Yes': return 2;
          default: return 0;
        }
      case 5: // Physical activity?
        switch (answer) {
          case 'Daily': return 10;
          case 'Several times a week': return 8;
          case 'Rarely': return 4;
          case 'Never': return 1;
          default: return 0;
        }
      case 6: // Difficulty focusing?
        switch (answer) {
          case 'No': return 10;
          case 'Sometimes': return 6;
          case 'Yes': return 2;
          default: return 0;
        }
      case 7: // Social media time?
        switch (answer) {
          case 'Less than 1 hour': return 10;
          case '1-3 hours': return 7;
          case '4-6 hours': return 4;
          case 'More than 6 hours': return 1;
          default: return 0;
        }
      case 8: // Compare on social media?
        switch (answer) {
          case 'Never': return 10;
          case 'Rarely': return 7;
          case 'Sometimes': return 4;
          case 'Often': return 1;
          default: return 0;
        }
      case 9: // Anxious without phone?
        switch (answer) {
          case 'No': return 10;
          case 'Sometimes': return 6;
          case 'Yes': return 2;
          default: return 0;
        }
      default:
        return 0;
    }
  }

  String _getScoreMessage(int score) {
    if (score >= 80) {
      return 'Great job! Your mental health is thriving.';
    } else if (score >= 60) {
      return 'Good effort! You’re on a healthy path.';
    } else if (score >= 40) {
      return 'Take some time to focus on self-care.';
    } else {
      return 'Consider seeking support for your mental well-being.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Background with gradient and score display
                Container(
                  height: 400,
                  decoration: const BoxDecoration(
                    color: Color(0xff9bb068),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                            const Text(
                              'NORMAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentScore.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getScoreMessage(_currentScore),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Date and History Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mental Score History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.history, color: Colors.grey),
                            onPressed: () {
                              // Add history navigation or action here if needed
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._mentalScoreHistory.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry['date'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      entry['mood'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      entry['recommendation'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: entry['score'] / 100,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          entry['score'] >= 80 ? Colors.green : Colors.orange,
                                        ),
                                        strokeWidth: 6,
                                      ),
                                      Text(
                                        entry['score'].toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment(0, 1),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFooterButton(
                    icon: Icons.home,
                    isActive: true,
                    onPressed: () {
                      // Navigate to Home page
                    },
                  ),
                  _buildFooterButton(
                    icon: Icons.message,
                    isActive: false,
                    onPressed: () {
                      // Navigate to Community page
                    },
                  ),
                  _buildFooterButton(
                    icon: Icons.chat,
                    isActive: false,
                    onPressed: () {
                      // Navigate to Chatbot page
                    },
                  ),
                  _buildFooterButton(
                    icon: Icons.bar_chart,
                    isActive: false,
                    onPressed: () {
                      // Navigate to Dashboard page
                    },
                  ),
                  _buildFooterButton(
                    icon: Icons.person,
                    isActive: false,
                    onPressed: () {
                      // Navigate to Profile page
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
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
              onPressed: onPressed,
            ),
          ],
        ),
      ],
    );
  }
}