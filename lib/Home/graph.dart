import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  int _currentScore = 0;
  List<Map<String, dynamic>> _mentalScoreHistory = [];
  List<Map<String, dynamic>> _moodHistory = [];

  @override
  void initState() {
    super.initState();
    _calculateInitialScore();
    _loadHistory();
    _loadMoodHistory();
  }

  Future<void> _calculateInitialScore() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final moodEntry = await supabase
            .from('mood_entries')
            .select('score')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1)
            .single();

        final moodScore = moodEntry['score'] as int? ?? 0;

        final responses = await supabase
            .from('questionnaire_responses')
            .select('question_number, answer, score')
            .eq('user_id', user.id)
            .gte('question_number', 2)
            .lte('question_number', 21);

        int totalQuestionScore = 0;
        for (var response in responses) {
          final score = response['score'] as int? ??
              _calculateQuestionScore(
                  response['question_number'] as int, response['answer'] as String);
          totalQuestionScore += score;
        }

        final combinedScore = (moodScore + totalQuestionScore) / 2;
        _currentScore = combinedScore.round();

        final today = DateFormat('dd MMM').format(DateTime.now()).toUpperCase();
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
          await supabase.from('mental_score_history').update({
            'score': _currentScore,
            'mood': _getMoodFromScore(_currentScore),
            'recommendation': _getScoreMessage(_currentScore),
          }).eq('id', existingEntry['id']);
        }

        setState(() {});
      }
    } catch (e) {
      setState(() {
        _currentScore = 0;
      });
      print('Error calculating score: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final history = await supabase
            .from('mental_score_history')
            .select('date, score, mood, timestamp')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(7);

        setState(() {
          _mentalScoreHistory = _getLast7DaysData(List<Map<String, dynamic>>.from(history));
        });
      }
    } catch (e) {
      setState(() {
        _mentalScoreHistory = _getLast7DaysData([]);
      });
      print('Error loading history: $e');
    }
  }

  Future<void> _loadMoodHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final history = await supabase
            .from('mood_entries')
            .select('mood, timestamp')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(7);

        setState(() {
          final fetchedMoods = List<Map<String, dynamic>>.from(history);
          print('Fetched Moods: $fetchedMoods'); // Debug print
          _moodHistory = _getLast7DaysMoods(fetchedMoods);
          print('Processed Mood History: $_moodHistory'); // Debug print
        });
      }
    } catch (e) {
      setState(() {
        _moodHistory = _getLast7DaysMoods([]);
      });
      print('Error loading mood history: $e');
    }
  }

  List<Map<String, dynamic>> _getLast7DaysData(List<Map<String, dynamic>> history) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> last7Days = [];
    final daysOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('dd MMM').format(date).toUpperCase();
      final dayOfWeek = daysOfWeek[date.weekday % 7];

      final entry = history.firstWhere(
            (e) => e['date'] == formattedDate,
        orElse: () => {'date': formattedDate, 'score': 0, 'mood': 'N/A'},
      );

      last7Days.add({
        'date': dayOfWeek,
        'score': entry['score'] as int? ?? 0,
        'mood': entry['mood'] as String? ?? 'N/A',
      });
    }
    return last7Days;
  }

  List<Map<String, dynamic>> _getLast7DaysMoods(List<Map<String, dynamic>> fetchedMoods) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> last7Days = [];
    final daysOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    // Process fetched moods into a map for quick lookup
    final moodMap = <String, String>{};
    for (var entry in fetchedMoods) {
      final date = DateTime.parse(entry['timestamp'] as String);
      final formattedDate = DateFormat('dd MMM').format(date).toUpperCase();
      moodMap[formattedDate] = entry['mood'] as String? ?? 'Neutral';
    }

    // Fill last 7 days, newest to oldest
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('dd MMM').format(date).toUpperCase();
      final dayOfWeek = daysOfWeek[date.weekday % 7];

      final mood = moodMap[formattedDate] ?? 'N/A';
      last7Days.add({
        'mood': mood,
        'day': dayOfWeek,
      });
    }
    return last7Days;
  }

  int _calculateQuestionScore(int questionNumber, String answer) {
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
    if (score >= 61) return 'Happy';
    if (score >= 41) return 'Neutral';
    if (score >= 21) return 'Sad';
    return 'Anxious, Depressed';
  }

  String _getScoreMessage(int score) {
    if (score >= 81) return 'Excellent! Your mental health is thriving.';
    if (score >= 61) return 'Good job! You’re on a healthy path.';
    if (score >= 41) return 'Fair. Consider some self-care practices.';
    if (score >= 21) return 'Needs attention. Seek support if needed.';
    return 'Critical. Please consult a professional.';
  }

  Color _getBarColor(String mood) {
    switch (mood) {
      case 'Very Happy':
      case 'Happy':
        return Colors.green;
      case 'Neutral':
        return Colors.lightGreen;
      case 'Sad':
        return Colors.orange;
      case 'Anxious, Depressed':
      default:
        return Colors.red;
    }
  }

  String _getEmojiFromMood(String? mood) {
    switch (mood) {
      case 'Very Happy':
        return '😄';
      case 'Happy':
        return '🙂';
      case 'Neutral':
        return '😐';
      case 'Sad':
        return '😢';
      case 'Anxious, Depressed':
        return '😞';
      case 'N/A':
        return '😐'; // Use neutral for N/A instead of sad
      default:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    String month = DateFormat('MMM').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xfff4eee0),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Score',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(Icons.help_outline, color: Colors.black),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'See your mental score insights',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.circle, color: Colors.green, size: 12),
                                    const SizedBox(width: 4),
                                    const Text('Positive', style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.circle, color: Colors.red, size: 12),
                                    const SizedBox(width: 4),
                                    const Text('Negative', style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              month,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const Text(
                              'Last 7 Days',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              child: _mentalScoreHistory.isEmpty
                                  ? const Center(child: Text('No data available'))
                                  : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 && index < _mentalScoreHistory.length) {
                                            return SideTitleWidget(
                                              space: 4,
                                              child: Transform.rotate(
                                                angle: 0,
                                                child: Text(
                                                  _mentalScoreHistory[index]['date'],
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              meta: meta,
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  barGroups: _mentalScoreHistory.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final data = entry.value;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: data['score'].toDouble(),
                                          color: _getBarColor(data['mood']),
                                          width: 16,
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              'Mood History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _moodHistory.map((mood) {
                                String emoji = _getEmojiFromMood(mood['mood']);
                                return Column(
                                  children: [
                                    Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mood['day'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.favorite, color: Colors.green, size: 24),
                            const Text(
                              'Recommendations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '$_currentScore+',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, 1),
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
                    onPressed: () {},
                  ),
                  _buildFooterButton(
                    icon: Icons.message,
                    isActive: false,
                    onPressed: () {},
                  ),
                  _buildFooterButton(
                    icon: Icons.chat,
                    isActive: false,
                    onPressed: () {},
                  ),
                  _buildFooterButton(
                    icon: Icons.bar_chart,
                    isActive: false,
                    onPressed: () {},
                  ),
                  _buildFooterButton(
                    icon: Icons.person,
                    isActive: false,
                    onPressed: () {},
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
              icon: Icon(
                icon,
                size: 30,
                color: isActive ? Colors.blue : Colors.grey,
              ),
              onPressed: onPressed,
            ),
          ],
        ),
      ],
    );
  }
}