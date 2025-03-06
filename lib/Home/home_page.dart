import 'package:flutter/material.dart';
import 'package:mindhaven/Home/exercise_page.dart';
import 'package:mindhaven/Home/health_journal.dart';
import 'package:mindhaven/Home/photo_journal.dart';
import 'package:mindhaven/Home/profile.dart';
import 'package:mindhaven/assessment/mood_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindhaven/Home/daily_journal.dart';
import 'package:mindhaven/Home/mindfulhours.dart';
import 'package:mindhaven/Community/welcome.dart';
import 'package:pie_chart/pie_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName = 'User';
  String? profileImageUrl = 'https://via.placeholder.com/64';
  int streakCount = 0; // Start at 0 for new users
  int notifications = 3;
  bool _isProfileComplete = false;
  int _currentScore = 0; // Will be updated dynamically
  Future<void> _calculateStreak() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    DateTime today = DateTime.now().toUtc();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    int streak = 0;

    // Check today
    final journalToday = await supabase
        .from('journal_entries')
        .select('id')
        .eq('user_id', user.id)
        .gte('timestamp', startOfToday.toIso8601String())
        .lt('timestamp', startOfToday.add(Duration(days: 1)).toIso8601String());

    final exerciseToday = await supabase
        .from('exercise_entries')
        .select('id')
        .eq('user_id', user.id)
        .gte('timestamp', startOfToday.toIso8601String())
        .lt('timestamp', startOfToday.add(Duration(days: 1)).toIso8601String());

    final photoToday = await supabase
        .from('photo_entries')
        .select('id')
        .eq('user_id', user.id)
        .gte('timestamp', startOfToday.toIso8601String())
        .lt('timestamp', startOfToday.add(Duration(days: 1)).toIso8601String());

    if (journalToday.isNotEmpty && exerciseToday.isNotEmpty && photoToday.isNotEmpty) {
      streak += 1;
    } else {
      // If today isn't complete, streak is 0
      setState(() {
        streakCount = streak;
      });
      return;
    }

    // Check previous days
    DateTime checkDay = startOfToday.subtract(Duration(days: 1));
    while (true) {
      final journalCheck = await supabase
          .from('journal_entries')
          .select('id')
          .eq('user_id', user.id)
          .gte('timestamp', checkDay.toIso8601String())
          .lt('timestamp', checkDay.add(Duration(days: 1)).toIso8601String());

      final exerciseCheck = await supabase
          .from('exercise_entries')
          .select('id')
          .eq('user_id', user.id)
          .gte('timestamp', checkDay.toIso8601String())
          .lt('timestamp', checkDay.add(Duration(days: 1)).toIso8601String());

      final photoCheck = await supabase
          .from('photo_entries')
          .select('id')
          .eq('user_id', user.id)
          .gte('timestamp', checkDay.toIso8601String())
          .lt('timestamp', checkDay.add(Duration(days: 1)).toIso8601String());

      if (journalCheck.isNotEmpty && exerciseCheck.isNotEmpty && photoCheck.isNotEmpty) {
        streak += 1;
        checkDay = checkDay.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    setState(() {
      streakCount = streak;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      if (!_isProfileComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MoodPage()),
          );
        });
      } else {
        _calculateCurrentScore(); // Calculate score only if assessment is complete
        _calculateStreak();
      }
    });
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single()
          .catchError((e) {
        print('Error fetching profile: $e');
        return null;
      });

      final responses = await supabase
          .from('questionnaire_responses')
          .select('question_number')
          .eq('user_id', user.id);
      final isAssessmentComplete = responses.length >= 11;

      setState(() {
        userName = response?['full_name']?.split(' ')?.first ??
            user.email?.split('@')[0] ??
            'User';
        profileImageUrl = response?['avatar_url'] ??
            'https://via.placeholder.com/64';
        _isProfileComplete = isAssessmentComplete;
      });
    }
  }

  Future<void> _calculateCurrentScore() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('No user logged in');
        setState(() => _currentScore = 0);
        return;
      }

      // Check activity entry counts
      final journalCount = (await supabase
          .from('journal_entries')
          .select('id')
          .eq('user_id', user.id)).length;
      print('Journal entries count: $journalCount');

      final exerciseCount = (await supabase
          .from('exercise_entries')
          .select('id')
          .eq('user_id', user.id)).length;
      print('Exercise entries count: $exerciseCount');

      final photoCount = (await supabase
          .from('photo_entries')
          .select('id')
          .eq('user_id', user.id)).length;
      print('Photo entries count: $photoCount');

      if (journalCount == 0 && exerciseCount == 0 && photoCount == 0) {
        print('No activity entries, using initial assessment score');
        // Fetch mood score (consistent with ScorePage)
        final moodEntryResponse = await supabase
            .from('mood_entries')
            .select('score')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1);
        final moodScore = moodEntryResponse.isNotEmpty
            ? (moodEntryResponse[0]['score'] as int? ?? 0)
            : 0;
        print('Mood score: $moodScore');

        // Fetch questionnaire responses (questions 2-21, like ScorePage)
        final responses = await supabase
            .from('questionnaire_responses')
            .select('question_number, answer, score')
            .eq('user_id', user.id)
            .gte('question_number', 2)
            .lte('question_number', 21);

        if (responses.isEmpty) {
          print('No questionnaire responses found');
          setState(() => _currentScore = moodScore);
          return;
        }

        int totalQuestionScore = 0;
        for (var response in responses) {
          final questionNumber = response['question_number'] as int;
          final answer = response['answer'] as String;
          final score = response['score'] as int? ?? _calculateQuestionScore(questionNumber, answer);
          totalQuestionScore += score;
        }
        print('Total question score: $totalQuestionScore from ${responses.length} responses');

        // Combine mood and question scores (match ScorePage logic)
        final combinedScore = (moodScore + totalQuestionScore) / 2;
        print('Initial combined score: $combinedScore');

        setState(() {
          _currentScore = combinedScore.round();
        });
      } else {
        print('Calculating score from activity moods');
        // Fetch latest moods
        final journalMoodResponse = await supabase
            .from('journal_entries')
            .select('mood')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1);
        final journalMood = journalMoodResponse.isNotEmpty
            ? journalMoodResponse[0]['mood'] as String?
            : null;
        print('Latest journal mood: $journalMood');

        final exerciseMoodResponse = await supabase
            .from('exercise_entries')
            .select('mood')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1);
        final exerciseMood = exerciseMoodResponse.isNotEmpty
            ? exerciseMoodResponse[0]['mood'] as String?
            : null;
        print('Latest exercise mood: $exerciseMood');

        final photoMoodResponse = await supabase
            .from('photo_entries')
            .select('mood')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1);
        final photoMood = photoMoodResponse.isNotEmpty
            ? photoMoodResponse[0]['mood'] as String?
            : null;
        print('Latest photo mood: $photoMood');

        // Calculate mood values
        int moodValue1 = _getMoodValue(journalMood);
        int moodValue2 = _getMoodValue(exerciseMood);
        int moodValue3 = _getMoodValue(photoMood);
        print('Mood values - Journal: $moodValue1, Exercise: $moodValue2, Photo: $moodValue3');

        // Average and scale to 0-100
        double averageMood = (moodValue1 + moodValue2 + moodValue3) / 3.0;
        int newScore = ((averageMood - 1) / 4 * 100).round();
        print('Average mood: $averageMood, Activity-based score: $newScore');

        setState(() {
          _currentScore = newScore;
        });
      }
    } catch (e) {
      print('Error calculating current score: $e');
      setState(() {
        _currentScore = 0;
      });
    }
  }

  int _calculateQuestionScore(int questionNumber, String answer) {
    // Matching ScorePage's scoring logic for questions 2-21
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
  int _getMoodValue(String? mood) {
    if (mood == null) return 3; // Default to Neutral if null
    String normalizedMood = mood.trim().toLowerCase();
    switch (normalizedMood) {
      case 'very sad': return 1;
      case 'sad': return 2;
      case 'neutral': return 3;
      case 'happy': return 4;
      case 'very happy': return 5;
      default:
        print('Unknown mood: $mood, defaulting to 3');
        return 3; // Default to Neutral
    }
  }

  String _getScoreStatus(int score) {
    if (score >= 81) return 'Healthy';
    else if (score >= 61) return 'Good';
    else if (score >= 41) return 'Fair';
    else if (score >= 21) return 'Needs Attention';
    else return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Stack(
              children: [
                Container(
                  color: const Color(0xfff4eee0),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top section (unchanged)
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: MediaQuery.of(context).size.height * 0.02,
                            ),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(MediaQuery.of(context).size.width * 0.1),
                                bottomRight: Radius.circular(MediaQuery.of(context).size.width * 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () {},
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: MediaQuery.of(context).size.width * 0.37,
                                        top: MediaQuery.of(context).size.height * 0.01,
                                      ),
                                      child: Text(
                                        DateFormat('EEE, d MMM yyyy').format(DateTime.now()),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Stack(
                                        children: [
                                          const Icon(Icons.notifications, size: 30),
                                          if (notifications > 0)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 14,
                                                  minHeight: 14,
                                                ),
                                                child: Text(
                                                  '$notifications',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    height: 1,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                                Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: MediaQuery.of(context).size.width * 0.04,
                                      ),
                                      child: CircleAvatar(
                                        radius: orientation == Orientation.portrait
                                            ? MediaQuery.of(context).size.width * 0.1
                                            : MediaQuery.of(context).size.height * 0.1,
                                        backgroundImage: NetworkImage(profileImageUrl!),
                                      ),
                                    ),
                                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hi, $userName',
                                          style: TextStyle(
                                            fontSize: orientation == Orientation.portrait ? 30 : 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.local_fire_department, size: 20),
                                            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                            Text('$streakCount'),

                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.03,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MoodPage()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9BB068),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                  ),
                                ),
                                child: Text(
                                  'Reassessment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: orientation == Orientation.portrait ? 16 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.03,
                            ),
                            child: Text(
                              'Mental Health Metrics',
                              style: TextStyle(
                                fontSize: orientation == Orientation.portrait ? 20 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.width * 0.03,
                                  ),
                                  child: _buildMetricButton(
                                    title: 'Score',
                                    value: _getScoreStatus(_currentScore),
                                    color: const Color(0xFF9BB068),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/score');
                                    },
                                    orientation: orientation,
                                    isScoreButton: true,
                                  ),
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.03),

                                Padding(
                                  padding: EdgeInsets.only(
                                    right: MediaQuery.of(context).size.width * 0.03,
                                  ),
                                  child: _buildMetricButton(
                                    title: 'Health Journal',
                                    value: 'Calendar',
                                    color: const Color(0xFFA18FFF),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => HealthJournalPage()));
                                    },
                                    titleAlignment: TextAlign.center,
                                    orientation: orientation,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.03,
                            ),
                            child: Text(
                              'Mindful Tracker',
                              style: TextStyle(
                                fontSize: orientation == Orientation.portrait ? 20 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.03,
                                vertical: MediaQuery.of(context).size.height * 0.01,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                                  _buildTrackerButton(
                                    icon: Icons.access_time,
                                    title: 'Mindful Hours',
                                    value: '2.5/8h',
                                    color: Colors.green,
                                    orientation: orientation,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ExercisePage()),
                                      );
                                    },
                                  ),

                                  _buildTrackerButton(
                                    icon: Icons.book,
                                    title: 'Mindful Journal',
                                    value: '$streakCount Day Streak', // Use overall streak
                                    color: Colors.orange,
                                    orientation: orientation,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => JournalPage()),
                                      );
                                    },
                                  ),
                                  _buildTrackerButton(
                                    icon: Icons.psychology,
                                    title: 'Stress Level',
                                    value: 'Level 3 (Normal)',
                                    color: Colors.yellow,
                                    orientation: orientation,
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/stress');
                                    },
                                  ),
                                  _buildTrackerButton(
                                    icon: Icons.mood,
                                    title: 'Mood Tracker',
                                    value: 'SAD → NEUTRAL → HAPPY',
                                    color: Colors.pink,
                                    orientation: orientation,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MoodPage()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.1,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(MediaQuery.of(context).size.width * 0.1),
              topRight: Radius.circular(MediaQuery.of(context).size.width * 0.1),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CommunityWelcomePage()),
                  );
                },
              ),
              _buildFooterButton(
                icon: Icons.camera,
                isActive: false,
                onPressed: () {Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PhotoJournalPage()));},
              ),
              _buildFooterButton(
                icon: Icons.timelapse_rounded,
                isActive: false,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExercisePage()),
                  );
                },
              ),
              _buildFooterButton(
                icon: Icons.person,
                isActive: false,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricButton({
    required String title,
    required String value,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    TextAlign titleAlignment = TextAlign.left,
    required Orientation orientation,
    bool isScoreButton = false,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      height: MediaQuery.of(context).size.height * 0.25,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Button background (e.g., 0xFF9BB068 for Score)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScoreButton)
              SizedBox(
                width: 120, // Outer radius
                height: 120, // Outer radius
                child: PieChart(
                  dataMap: {
                    'Score': _currentScore.toDouble(),
                    'Remaining': 100 - _currentScore.toDouble(),
                  },
                  chartRadius: 60, // Half of the size for a mini pie chart
                  chartType: ChartType.ring,
                  ringStrokeWidth: 20, // Inner radius of the ring
                  colorList: [
                    Colors.white, // Filled portion (Score)
                    Colors.transparent, // Unfilled portion (Remaining), shows button background
                  ],
                  legendOptions: const LegendOptions(showLegends: false), // Hide legend
                  chartValuesOptions: const ChartValuesOptions(
                    showChartValues: false, // Hide numerical values on the chart
                  ),
                  centerText: _currentScore.toString(),
                  centerTextStyle: TextStyle(
                    fontSize: orientation == Orientation.portrait ? 40 : 34,
                    color: const Color(0xFF9BB068), // Green text for score
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.circle,
                size: MediaQuery.of(context).size.width * 0.1,
                color: textColor,
              ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: orientation == Orientation.portrait ? 16 : 12,
                color: textColor,
              ),
              textAlign: titleAlignment,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              value,
              style: TextStyle(
                fontSize: orientation == Orientation.portrait ? 18 : 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerButton({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Orientation orientation,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.12,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.06,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: MediaQuery.of(context).size.width * 0.05),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: orientation == Orientation.portrait ? 16 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: orientation == Orientation.portrait ? 14 : 10,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
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
                width: MediaQuery.of(context).size.width * 0.12,
                height: MediaQuery.of(context).size.width * 0.12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: Icon(
                icon,
                size: MediaQuery.of(context).size.width * 0.08,
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

class SleepTrackingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sleep Tracking")),
      body: Center(child: Text("Sleep Tracking Page")),
    );
  }
}