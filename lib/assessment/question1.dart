import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({Key? key}) : super(key: key);

  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  int _currentQuestion = 1;
  String? _selectedOption;
  final Map<int, String?> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'number': 1,
      'text': 'How would you rate your current mood?',
      'options': {
        'Very Good': Icons.sentiment_very_satisfied,
        'Good': Icons.sentiment_satisfied,
        'Neutral': Icons.sentiment_neutral,
        'Bad': Icons.sentiment_dissatisfied,
        'Very Bad': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 2,
      'text': 'I feel sad and low',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 3,
      'text': 'I feel anxious or nervous',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 4,
      'text': 'I have difficulty concentrating',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 5,
      'text': 'I feel tired or have low energy',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 6,
      'text': 'I have lost interest in things I usually enjoy',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 7,
      'text': 'I feel worthless or guilty',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 8,
      'text': 'I have trouble making decisions',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 9,
      'text': 'I feel irritable or angry',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 10,
      'text': 'I have physical symptoms like headaches or stomach aches',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 11,
      'text': 'I feel hopeless about the future',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 12,
      'text': 'I have changes in my appetite',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 13,
      'text': 'I feel restless or slowed down',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 14,
      'text': 'I have thoughts of harming myself',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 15,
      'text': 'I feel disconnected from others',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 16,
      'text': 'I have difficulty remembering things',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 17,
      'text': 'I feel overwhelmed by daily tasks',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 18,
      'text': 'I have trouble relaxing',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 19,
      'text': 'I feel like I\'m a burden to others',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 20,
      'text': 'I have lost confidence in myself',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
    {
      'number': 21,
      'text': 'My sleep is disturbed (unrestful or broken sleep)',
      'options': {
        'Never': Icons.sentiment_satisfied,
        'Hardly ever': Icons.sentiment_neutral,
        'Some of the time': Icons.sentiment_dissatisfied,
        'Most of the time': Icons.sentiment_very_dissatisfied,
        'All the time': Icons.sentiment_very_dissatisfied,
      }
    },
  ];

  int _calculateScore(String? answer) {
    switch (answer) {
      case 'Very Good':
      case 'Never':
        return 5;
      case 'Good':
      case 'Hardly ever':
        return 4;
      case 'Neutral':
      case 'Some of the time':
        return 3;
      case 'Bad':
      case 'Most of the time':
        return 2;
      case 'Very Bad':
      case 'All the time':
        return 1;
      default:
        return 0;
    }
  }

  void _saveAnswerAndNavigate() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option.')),
      );
      return;
    }

    _answers[_currentQuestion] = _selectedOption;
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final score = _calculateScore(_selectedOption);
        await supabase.from('questionnaire_responses').upsert({
          'user_id': user.id,
          'question_number': _currentQuestion,
          'answer': _selectedOption,
          'score': score,
        });
      }

      if (_currentQuestion < _questions.length) {
        setState(() {
          _currentQuestion++;
          _selectedOption = _answers[_currentQuestion]; // Load previous answer if exists
        });
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving answer: $e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentQuestion > 1) {
      setState(() {
        _currentQuestion--;
        _selectedOption = _answers[_currentQuestion];
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentQuestion - 1];
    final progress = _currentQuestion / _questions.length;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xfff4eee0),
        appBar: AppBar(
          backgroundColor: const Color(0xfff4eee0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _onWillPop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 111.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF926247),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Question $_currentQuestion of ${_questions.length}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: const Color(0xFF9BB068),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 20),
              Text(
                currentQ['text'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/images/question.png',
                width: 130,
                height: 130,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: currentQ['options'].length,
                  itemBuilder: (context, index) {
                    final option = currentQ['options'].keys.elementAt(index);
                    final icon = currentQ['options'][option];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOption = option;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: _selectedOption == option
                                ? Border.all(color: const Color(0xFF9BB068), width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, color: Colors.black, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    option,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Radio<String>(
                                value: option,
                                groupValue: _selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOption = value;
                                  });
                                },
                                activeColor: const Color(0xFF9BB068),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAnswerAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF926247),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continue ',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}