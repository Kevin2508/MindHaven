import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushNamed(context, '/EnterNamePage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildPage(
                        title: 'Welcome to MindHaven',
                        description:
                        'Your journey to better mental health starts here. Take our assessment to understand your needs.',
                        imagePath: 'assets/images/angel.png',
                        orientation: orientation,
                      ),
                      _buildPage(
                        title: 'Personalized Insights',
                        description:
                        'Get tailored recommendations based on your responses to improve your well-being.',
                        imagePath: 'assets/images/great.png',
                        orientation: orientation,
                      ),
                      _buildPage(
                        title: 'Start Your Journey',
                        description:
                        'Click below to begin the assessment and take the first step towards a healthier you.',
                        imagePath: 'assets/images/Meditate.png',
                        orientation: orientation,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          3,
                              (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? const Color(0xFF9BB068)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF926247),
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.3, MediaQuery.of(context).size.height * 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _currentPage < 2 ? 'Next' : 'Get Started',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String imagePath,
    required Orientation orientation,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: orientation == Orientation.portrait ? 28 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E4A2E),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Image.asset(
            imagePath,
            height: orientation == Orientation.portrait
                ? MediaQuery.of(context).size.height * 0.3
                : MediaQuery.of(context).size.width * 0.3,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: orientation == Orientation.portrait ? 16 : 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}