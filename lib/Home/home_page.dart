import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindhaven/Community/community.dart';
import 'package:mindhaven/Home/exercise_page.dart';
import 'package:mindhaven/Home/health_journal.dart';
import 'package:mindhaven/Home/photo_journal.dart';
import 'package:mindhaven/Home/profile.dart';
import 'package:mindhaven/assessment/mood_page.dart';
import 'package:mindhaven/chat/chat_provider.dart';
import 'package:mindhaven/chat/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindhaven/Home/daily_journal.dart';
import 'package:mindhaven/Home/mindfulhours.dart';
import 'package:mindhaven/Community/welcome.dart';
import 'package:mindhaven/Services/notification_page.dart';
import 'package:provider/provider.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = 'User';
  String profileImageUrl = 'https://via.placeholder.com/64';
  int streakCount = 0;
  int notifications = 3;
  bool _isProfileComplete = false;
  int _currentScore = 0;
  bool _isAssessmentDoneToday = false;
  int _chatSessionCount = 0;

  @override
  void initState() {

    super.initState();

    _initializeData();
  }
  Future<void> _fetchChatSessionCount() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadSessions(); // Ensure sessions are loaded
    setState(() {
      _chatSessionCount = chatProvider.sessionIds.length; // Update session count
    });
  }
  Future<void> _initializeData() async {
    try {
      await _loadUserData();
      if (!_isProfileComplete) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoodPage()),
          );
        }
      } else {
        await Future.wait([
          _calculateCurrentScore(),
          _calculateStreak(),
          _fetchChatSessionCount(), // Fetch chat session count
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing data: $e')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single();

      final responses = await supabase
          .from('questionnaire_responses')
          .select('question_number')
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          userName = response['full_name']?.toString().split(' ').first ??
              user.email?.split('@')[0] ??
              'User';
          profileImageUrl = response['avatar_url']?.toString() ??
              'https://via.placeholder.com/64';
          _isProfileComplete = responses.length >= 11;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = user.email?.split('@')[0] ?? 'User';
          profileImageUrl = 'https://via.placeholder.com/64';
          _isProfileComplete = false;
        });
      }
    }
  }

  Future<void> _calculateStreak() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final history = await supabase
          .from('mental_score_history')
          .select('date')
          .eq('user_id', user.id);

      final uniqueDays = (history as List)
          .map((entry) => entry['date'] as String)
          .toSet()
          .length;

      if (mounted) {
        setState(() => streakCount = uniqueDays);
      }
    } catch (e) {
      if (mounted) {
        setState(() => streakCount = 0);
      }
    }
  }

  Future<void> _checkHowYouFeelToday() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final today = DateFormat('dd MMM').format(DateTime.now()).toUpperCase();
      final todayEntry = await supabase
          .from('mental_score_history')
          .select('id')
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (mounted) {
        setState(() => _isAssessmentDoneToday = todayEntry != null);
      }

      if (_isAssessmentDoneToday) {
        await Future.wait([_calculateStreak(), _calculateCurrentScore()]);
        return;
      }

      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoodPage()),
        );

        if (result == true && mounted) {
          await Future.wait([_calculateStreak(), _calculateCurrentScore()]);
          setState(() => _isAssessmentDoneToday = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking mood: $e')),
        );
      }
    }
  }

  Future<void> _calculateCurrentScore() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final latestScoreEntry = await supabase
          .from('mental_score_history')
          .select('score')
          .eq('user_id', user.id)
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      if (mounted) {
        setState(() {
          _currentScore = latestScoreEntry['score'] as int? ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentScore = 0);
      }
    }
  }

  String _getScoreStatus(int score) {
    if (score >= 81) return 'Healthy';
    if (score >= 61) return 'Good';
    if (score >= 41) return 'Fair';
    if (score >= 21) return 'Needs Attention';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
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
                          minHeight: MediaQuery.of(context).size.height,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(orientation),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                            if (!_isAssessmentDoneToday) _buildMoodButton(orientation),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                            _buildSectionTitle('Mental Health Metrics', orientation),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                            _buildMetricsRow(orientation),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                            _buildSectionTitle('AI Therapy Chatbot', orientation),
                            _buildChatbotButton(),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                            _buildSectionTitle('Mindful Tracker', orientation),
                            _buildTrackerButtons(orientation),
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
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildHeader(Orientation orientation) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(MediaQuery.of(context).size.width * 0.1),
          bottomRight: Radius.circular(MediaQuery.of(context).size.width * 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
              Padding(
                padding: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.37,
                  top: MediaQuery.of(context).size.height * 0.01,
                ),
                child: Text(
                  DateFormat('EEE, d MMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
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
                padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.04),
                child: CircleAvatar(
                  radius: orientation == Orientation.portrait
                      ? MediaQuery.of(context).size.width * 0.1
                      : MediaQuery.of(context).size.height * 0.1,
                  backgroundImage: NetworkImage(profileImageUrl),
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
    );
  }

  Widget _buildMoodButton(Orientation orientation) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03),
        child: ElevatedButton(
          onPressed: _checkHowYouFeelToday,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9BB068),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            ),
          ),
          child: Text(
            'How You Feel Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: orientation == Orientation.portrait ? 16 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Orientation orientation) {
    return Padding(
      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.03),
      child: Text(
        title,
        style: TextStyle(
          fontSize: orientation == Orientation.portrait ? 20 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricsRow(Orientation orientation) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.03),
            child: _buildMetricButton(
              title: 'Score',
              value: _getScoreStatus(_currentScore),
              color: const Color(0xFF9BB068),
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/score'),
              orientation: orientation,
              isScoreButton: true,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Padding(
            padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.03),
            child: _buildMetricButton(
              title: 'Health Journal',
              value: 'Calendar',
              color: const Color(0xFFA18FFF),
              textColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HealthJournalPage()),
              ),
              titleAlignment: TextAlign.center,
              orientation: orientation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10.0, right: 10.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff926247),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xff926247),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_chatSessionCount',
                      style: TextStyle(
                        fontSize: 54,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset('assets/images/reading.png', height: 130, width: 130),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerButtons(Orientation orientation) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.03,
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        child: Column(
          children: [
            _buildTrackerButton(
              icon: Icons.access_time,
              title: 'Mindful Hours',
              value: '2.5/8h',
              color: Colors.green,
              orientation: orientation,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExercisePage()),
              ),
            ),
            _buildTrackerButton(
              icon: Icons.book,
              title: 'Mindful Journal',
              value: '$streakCount Day Streak',
              color: Colors.orange,
              orientation: orientation,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JournalPage()),
              ),
            ),
            _buildTrackerButton(
              icon: Icons.mood,
              title: 'Mood Tracker',
              value: 'SAD → NEUTRAL → HAPPY',
              color: Colors.pink,
              orientation: orientation,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoodPage(),
                  settings: const RouteSettings(arguments: {'fromTracker': true}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
          _buildFooterButton(icon: Icons.home, isActive: true, onPressed: () {}),
          _buildFooterButton(
            icon: Icons.message,
            isActive: false,
            onPressed: _navigateToCommunity,
          ),
          _buildFooterButton(
            icon: Icons.camera,
            isActive: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhotoJournalPage()),
            ),
          ),
          _buildFooterButton(
            icon: Icons.timelapse_rounded,
            isActive: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExercisePage()),
            ),
          ),
          _buildFooterButton(
            icon: Icons.person,
            isActive: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunity() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CommunityPage()),
      );
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('is_first_time')
          .eq('id', user.id)
          .single();

      final isFirstTime = response['is_first_time'] as bool? ?? true;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isFirstTime
                ? const CommunityWelcomePage()
                : const CommunityPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityPage()),
        );
      }
    }
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
    if (title == 'Health Journal') {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.45,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Text(
                  'Health Journal',
                  style: TextStyle(
                    fontSize: orientation == Orientation.portrait ? 16 : 12,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.count(
                      crossAxisCount: 6,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      childAspectRatio: 1.0,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: List.generate(30, (index) {
                        double opacity = (index % 3 == 0) ? 1.0 : (index % 3 == 1) ? 0.6 : 0.3;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(opacity),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.45,
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
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
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
          mainAxisAlignment: MainAxisAlignment.start,
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
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: orientation == Orientation.portrait ? 14 : 10,
                      color: Colors.grey[600],
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
  Future<bool> _onBackPressed() async {
    // Show a confirmation dialog
    bool shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay in the app
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Exit the app
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    // If the user confirms, exit the app
    if (shouldExit ?? false) {
      SystemNavigator.pop(); // Close the app
    }

    // Return false to prevent default back navigation
    return false;
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
  const SleepTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sleep Tracking")),
      body: Center(child: Text("Sleep Tracking Page")),
    );
  }
}