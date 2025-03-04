import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName = 'User'; // Default name
  String? profileImageUrl = 'https://via.placeholder.com/64'; // Default image
  int streakCount = 5; // Example streak count
  int coinCount = 100; // Example coin count
  int notifications = 3; // Example notification count
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select('full_name')
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
        userName = response?['full_name']
            ?.split(' ')
            ?.first ??
            user.email?.split('@')[0] ??
            'User';
        _isProfileComplete = isAssessmentComplete;
      });
    }
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
                              vertical:
                              MediaQuery.of(context).size.height * 0.02,
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
                                bottomLeft: Radius.circular(
                                    MediaQuery.of(context).size.width * 0.1),
                                bottomRight: Radius.circular(
                                    MediaQuery.of(context).size.width * 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () {},
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: MediaQuery.of(context).size.width *
                                            0.37,
                                        top: MediaQuery.of(context).size.height *
                                            0.01,
                                      ),
                                      child: Text(
                                        DateFormat('EEE, d MMM yyyy')
                                            .format(DateTime.now()),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Stack(
                                        children: [
                                          const Icon(Icons.notifications,
                                              size: 30),
                                          if (notifications > 0)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding:
                                                const EdgeInsets.all(2),
                                                decoration:
                                                const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                const BoxConstraints(
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
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.02),
                                Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: MediaQuery.of(context).size.width *
                                            0.04,
                                      ),
                                      child: CircleAvatar(
                                        radius: orientation ==
                                            Orientation.portrait
                                            ? MediaQuery.of(context).size.width *
                                            0.1
                                            : MediaQuery.of(context).size.height *
                                            0.1,
                                        backgroundImage:
                                        NetworkImage(profileImageUrl!),
                                      ),
                                    ),
                                    SizedBox(
                                        width: MediaQuery.of(context).size.width *
                                            0.04),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hi, $userName',
                                          style: TextStyle(
                                            fontSize: orientation ==
                                                Orientation.portrait
                                                ? 30
                                                : 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.local_fire_department,
                                                size: 20),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                    0.01),
                                            Text('$streakCount'),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                    0.04),
                                            const Icon(Icons.monetization_on,
                                                size: 20),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                    0.01),
                                            Text('$coinCount'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03),
                          if (!_isProfileComplete)
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width *
                                      0.03,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/question3');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF9BB068),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.03),
                                    ),
                                  ),
                                  child: Text(
                                    'Reassessment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: orientation ==
                                          Orientation.portrait
                                          ? 16
                                          : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.03,
                            ),
                            child: Text(
                              'Mental Health Metrics',
                              style: TextStyle(
                                fontSize: orientation == Orientation.portrait
                                    ? 20
                                    : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.width *
                                        0.03,
                                  ),
                                  child: _buildMetricButton(
                                    title: 'Score',
                                    value: '80\nHealthy',
                                    color: const Color(0xFF9BB068),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/score');
                                    },
                                    orientation: orientation,
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.03),
                                _buildMetricButton(
                                  title: 'Mood Tracker',
                                  value: 'Sad',
                                  color: const Color(0xFFFE814B),
                                  textColor: Colors.white,
                                  onPressed: () {},
                                  titleAlignment: TextAlign.center,
                                  orientation: orientation,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.03),
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: MediaQuery.of(context).size.width *
                                        0.03,
                                  ),
                                  child: _buildMetricButton(
                                    title: 'Health Journal',
                                    value: 'Calendar',
                                    color: const Color(0xFFA18FFF),
                                    textColor: Colors.white,
                                    onPressed: () {},
                                    titleAlignment: TextAlign.center,
                                    orientation: orientation,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.03,
                            ),
                            child: Text(
                              'Mindful Tracker',
                              style: TextStyle(
                                fontSize: orientation == Orientation.portrait
                                    ? 20
                                    : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width *
                                  0.03,
                              vertical: MediaQuery.of(context).size.height *
                                  0.01,
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.02),
                                _buildTrackerItem(
                                  icon: Icons.access_time,
                                  title: 'Mindful Hours',
                                  value: '2.5/8h',
                                  color: Colors.green,
                                  orientation: orientation,
                                ),
                                _buildTrackerItem(
                                  icon: Icons.bed,
                                  title: 'Sleep Quality',
                                  value: 'Insomniac (~2h Avg)',
                                  color: Colors.purple,
                                  orientation: orientation,
                                ),
                                _buildTrackerItem(
                                  icon: Icons.book,
                                  title: 'Mindful Journal',
                                  value: '64 Day Streak',
                                  color: Colors.orange,
                                  orientation: orientation,
                                ),
                                _buildTrackerItem(
                                  icon: Icons.psychology,
                                  title: 'Stress Level',
                                  value: 'Level 3 (Normal)',
                                  color: Colors.yellow,
                                  orientation: orientation,
                                ),
                                _buildTrackerItem(
                                  icon: Icons.mood,
                                  title: 'Mood Tracker',
                                  value: 'SAD → NEUTRAL → HAPPY',
                                  color: Colors.pink,
                                  orientation: orientation,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.1),
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
              topLeft: Radius.circular(
                  MediaQuery.of(context).size.width * 0.1),
              topRight: Radius.circular(
                  MediaQuery.of(context).size.width * 0.1),
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
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      height: MediaQuery.of(context).size.height * 0.25,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.width * 0.04),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              size: MediaQuery.of(context).size.width * 0.1,
              color: textColor,
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: orientation == Orientation.portrait ? 16 : 12,
                color: textColor,
              ),
              textAlign: titleAlignment,
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.01),
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

  Widget _buildTrackerItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Orientation orientation,
  }) {
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.02),
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.12,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            MediaQuery.of(context).size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.06,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon,
                color: color, size: MediaQuery.of(context).size.width * 0.05),
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.04),
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
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01),
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