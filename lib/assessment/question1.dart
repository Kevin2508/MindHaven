import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionPage extends StatefulWidget {
  final int questionNumber;
  final String questionText;
  final Map<String, IconData> options;
  final int totalQuestions;

  const QuestionPage({
    Key? key,
    required this.questionNumber,
    required this.questionText,
    required this.options,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  String? _selectedOption;
  final Map<int, String?> _answers = {}; // Store answers for each question

  @override
  void initState() {
    super.initState();
    // Initialize with any previous answer if navigating back
    _answers[widget.questionNumber] = _answers[widget.questionNumber];
  }

  int _calculateScore(String? answer) {
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

  void _saveAnswerAndNavigate() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option.')),
      );
      return;
    }

    _answers[widget.questionNumber] = _selectedOption;
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final score = _calculateScore(_selectedOption);
        await supabase.from('questionnaire_responses').upsert({
          'user_id': user.id,
          'question_number': widget.questionNumber,
          'answer': _selectedOption,
          'score': score, // Add score to the response
        });
        print('Answer saved for question ${widget.questionNumber}: $_selectedOption with score $score');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving answer: $e')),
      );
      return;
    }

    if (widget.questionNumber < widget.totalQuestions) {
      Navigator.pushReplacementNamed(
        context,
        '/question${widget.questionNumber + 1}',
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<bool> _onWillPop() async {
    if (widget.questionNumber > 2) { // Start from question 2 since mood is question 1
      Navigator.pushReplacementNamed(
        context,
        '/question${widget.questionNumber - 1}',
      );
      return false;
    } else if (widget.questionNumber == 2) {
      Navigator.pushReplacementNamed(context, '/mood'); // Back to mood page
      return false;
    } else {
      return false; // Prevent default behavior for question 1 (mood)
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.questionNumber / widget.totalQuestions;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xfff4eee0),
        appBar: AppBar(
          backgroundColor: const Color(0xfff4eee0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _onWillPop();
            },
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
                    "Question ${widget.questionNumber} of ${widget.totalQuestions}",
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
              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: const Color(0xFF9BB068),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 20),
              // Question Text
              Text(
                widget.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Question Image
              Image.asset(
                'assets/images/question.png',
                width: 130,
                height: 130,
              ),
              const SizedBox(height: 10),
              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options.keys.elementAt(index);
                    final icon = widget.options[option];
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