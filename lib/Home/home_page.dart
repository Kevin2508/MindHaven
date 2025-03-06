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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName = 'User';
  String? profileImageUrl = 'https://via.placeholder.com/64';
  int streakCount = 0;
  int notifications = 3;
  bool _isProfileComplete = false;
  int _currentScore = 0;
  bool _isAssessmentDoneToday = false;

  Future<void> _calculateStreak() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch all unique dates from mental_score_history
      final history = await supabase
          .from('mental_score_history')
          .select('date')
          .eq('user_id', user.id);

      // Count unique days with reassessments
      final uniqueDays = (history as List).map((entry) => entry['date'] as String).toSet().length;

      setState(() {
        streakCount = uniqueDays;
      });
    } catch (e) {
      print('Error calculating streak: $e');
      setState(() {
        streakCount = 0;
      });
    }
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
        _calculateCurrentScore(); // Now matches ScorePage logic
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

  Future<void> _checkHowYouFeelToday() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get today's date in "DD MMM" format
      final today = DateFormat('dd MMM').format(DateTime.now()).toUpperCase();

      // Check if entry exists for today
      final todayEntry = await supabase
          .from('mental_score_history')
          .select('id')
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      setState(() {
        _isAssessmentDoneToday = todayEntry != null;
      });

      if (_isAssessmentDoneToday) {
        // Entry already exists, just refresh streak and score
        await _calculateStreak();
        await _calculateCurrentScore();
        return;
      }

      // Navigate to MoodPage if no entry for today
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MoodPage()),
      );

      // If MoodPage completes, refresh streak and score
      if (result == true) {
        await _calculateStreak();
        await _calculateCurrentScore();
        setState(() {
          _isAssessmentDoneToday = true; // Update flag after completion
        });
      }
    } catch (e) {
      print('Error in How You Feel Today: $e');
    }
  }

  Future<void> _calculateCurrentScore() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Fetch the latest score from mental_score_history
        final latestScoreEntry = await supabase
            .from('mental_score_history')
            .select('score')
            .eq('user_id', user.id)
            .order('timestamp', ascending: false)
            .limit(1)
            .single();

        setState(() {
          _currentScore = latestScoreEntry['score'] as int? ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching score from history: $e');
      setState(() {
        _currentScore = 0;
      });
    }
  }
  int _calculateQuestionScore(int questionNumber, String answer) {
    // Exact same logic as ScorePage
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
                          if (!_isAssessmentDoneToday)
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.03,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _checkHowYouFeelToday(); // Updated method name
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9BB068),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                                  ),
                                ),
                                child: Text(
                                  'How You Feel Today', // Renamed from "Reassessment"
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
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.03,
                            ),
                            child: Text(
                              'AI Therapy Chatbot',
                              style: TextStyle(
                                fontSize: orientation == Orientation.portrait ? 20 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top:10, left: 10.0, right: 10.0),
                            child: ElevatedButton(
                              onPressed: (){},

                              style: ElevatedButton.styleFrom(
                                
                                backgroundColor: Color(0xff926247),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 180,

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Color(0xff926247),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('2541', style: TextStyle(
                                          fontSize: 54,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold
                                        ),),
                                        Text('Conversations', style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold
                                        ),),
                                      ],
                                    ),
                                    SizedBox(width: 24),
                                    Image.asset('assets/images/reading.png',height: 140,width: 140,)
                                  ],
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
                                    value: '$streakCount Day Streak',
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
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PhotoJournalPage()));
                },
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
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScoreButton)
              Text(
                _currentScore.toString(),
                style: TextStyle(
                  fontSize: orientation == Orientation.portrait ? 50 : 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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