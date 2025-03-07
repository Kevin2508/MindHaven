import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({Key? key}) : super(key: key);

  @override
  _MoodPageState createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final List<Map<String, dynamic>> _moods = [
    {"name": "Happy", "emoji": "😄", "score": 90},
    {"name": "Sad", "emoji": "😢", "score": 30},
    {"name": "Angry", "emoji": "😡", "score": 10},
    {"name": "Calm", "emoji": "😌", "score": 80},
    {"name": "Excited", "emoji": "🤩", "score": 70},
    {"name": "Anxious", "emoji": "😰", "score": 25},
    {"name": "Tired", "emoji": "😪", "score": 20},
    {"name": "Stressed", "emoji": "😫", "score": 15},
    {"name": "Peaceful", "emoji": "😊", "score": 75},
  ];

  int _selectedIndex = 0;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveMoodAndNavigate() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save your mood.')),
      );
      return;
    }

    try {
      await supabase.from('mood_entries').insert({
        'user_id': user.id,
        'mood': _moods[_selectedIndex]["name"],
        'score': _moods[_selectedIndex]["score"],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood and score saved successfully!')),
      );
      Navigator.pushNamed(context, '/mood'); // Navigate to question 2
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving mood and score: $e')),
      );
      print('Error saving mood and score: $e');
    }
  }
  Future<bool> _onBackPressed() async {
    // Navigate to HomePage on back press
    Navigator.pushNamed(context, '/home');
    return false; // Prevent default back navigation
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4eee0),
      appBar: AppBar(
        backgroundColor: const Color(0xfff4eee0),
        elevation: 0,
        actions: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(right: 116.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF926247),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Question 1 of 21",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          const Text(
            "How would you describe your mood?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.black,
                  size: 50,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 270,
                      decoration: BoxDecoration(),
                    ),
                    SizedBox(
                      height: 300,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification) {
                            if (_scrollController.selectedItem == _moods.length - 1) {
                              _scrollController.jumpToItem(0);
                            } else if (_scrollController.selectedItem == 0) {
                              _scrollController.jumpToItem(_moods.length - 1);
                            }
                          }
                          return true;
                        },
                        child: ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: 300,
                          perspective: 0.003,
                          diameterRatio: 100.8,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _moods.length,
                            builder: (context, index) {
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _selectedIndex == index ? 1.0 : 0.3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: _selectedIndex == index
                                        ? [
                                      BoxShadow(
                                        color: Colors.yellow.withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 1,
                                      )
                                    ]
                                        : [],
                                  ),
                                  child: Text(
                                    _moods[index]["emoji"],
                                    style: const TextStyle(fontSize: 150),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 50,
                ),
                const SizedBox(height: 40),
                Text(
                  "I feel ${_moods[_selectedIndex]["name"].toLowerCase()}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveMoodAndNavigate,
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
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Urbanist',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}