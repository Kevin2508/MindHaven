import 'package:flutter/material.dart';
import 'package:mindhaven/Home/graph.dart';
import 'package:mindhaven/Home/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Added for date formatting

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  int _currentScore = 0; // Initial score will be calculated
  List<Map<String, dynamic>> _mentalScoreHistory = []; // Dynamic history list

  @override
  void initState() {
    super.initState();
    _calculateInitialScore();
    _loadHistory();
  }

  Future<void> _calculateInitialScore() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Fetch mood score
        final moodEntry = await supabase
            .from('mood_entries')
            .select('score')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1)
            .single();

        final moodScore = moodEntry['score'] as int? ?? 0;

        // Fetch question responses
        final responses = await supabase
            .from('questionnaire_responses')
            .select('question_number, answer, score')
            .eq('user_id', user.id)
            .gte('question_number', 2)
            .lte('question_number', 21);

        if (responses.isEmpty) {
          setState(() {
            _currentScore = 0;
          });
          return;
        }

        int totalQuestionScore = 0;
        for (var response in responses) {
          final questionNumber = response['question_number'] as int;
          final answer = response['answer'] as String;
          final score = response['score'] as int? ?? _calculateQuestionScore(questionNumber, answer);
          totalQuestionScore += score;
        }

        // Combine mood score (0-100) and question score (0-100), then normalize to 0-100
        final combinedScore = (moodScore + totalQuestionScore) / 2;
        _currentScore = combinedScore.round();

        // Save or update history for today
        final today = DateFormat('dd MMM').format(DateTime.now()).toUpperCase(); // Format as "04 MAR"
        final existingEntry = await supabase
            .from('mental_score_history')
            .select('id')
            .eq('user_id', user.id)
            .eq('date', today)
            .maybeSingle();

        if (existingEntry == null) {
          await supabase.from('mental_score_history').insert({
            'user_id': user.id,
            'score': _currentScore,
            'date': today,
            'mood': _getMoodFromScore(_currentScore),
            'recommendation': _getScoreMessage(_currentScore),
          });
        } else {
          await supabase
              .from('mental_score_history')
              .update({
            'score': _currentScore,
            'mood': _getMoodFromScore(_currentScore),
            'recommendation': _getScoreMessage(_currentScore),
          })
              .eq('id', existingEntry['id']);
        }

        setState(() {});
      }
    } catch (e) {
      print('Error calculating score: $e');
      setState(() {
        _currentScore = 0;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final history = await supabase
            .from('mental_score_history')
            .select('date, score, mood, recommendation')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(5); // Load last 5 unique days
        setState(() {
          _mentalScoreHistory = List<Map<String, dynamic>>.from(history);
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  int _calculateQuestionScore(int questionNumber, String answer) {
    // Scoring for questions 2-21 (5 points max per question)
    switch (answer) {
      case 'Never':
        return 5;
      case 'Hardly ever':
        return 4;
      case 'Some of the time':
        return 3;
      case 'Most of the time':
        return 2;
      case 'All the time':
        return 1;
      default:
        return 0;
    }
  }

  String _getMoodFromScore(int score) {
    if (score >= 81) return 'Very Happy';
    else if (score >= 61) return 'Happy';
    else if (score >= 41) return 'Neutral';
    else if (score >= 21) return 'Sad';
    else return 'Anxious, Depressed';
  }

  String _getScoreMessage(int score) {
    if (score >= 81) {
      return 'Excellent! Your mental health is thriving.';
    } else if (score >= 61) {
      return 'Good job! You’re on a healthy path.';
    } else if (score >= 41) {
      return 'Fair. Consider some self-care practices.';
    } else if (score >= 21) {
      return 'Needs attention. Seek support if needed.';
    } else {
      return 'Critical. Please consult a professional.';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 81) return Colors.green;
    else if (score >= 61) return Colors.lightGreen;
    else if (score >= 41) return Colors.yellow;
    else if (score >= 21) return Colors.orange;
    else return Colors.red;
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
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: (){
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GraphPage()));
                      },
                        style: ElevatedButton.styleFrom(
                          elevation: 0.1,

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),

                        child: Text('Check your Daily Data', style: TextStyle(color: Color(0xff9bb068),fontWeight: FontWeight.bold, fontSize: 16)),

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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    entry['date'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['mood'],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry['recommendation'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: entry['score'] / 100, // Filled based on history score
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getScoreColor(entry['score']),
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
                const SizedBox(height: 70),
                // Footer
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
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
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