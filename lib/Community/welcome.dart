import 'package:flutter/material.dart';
import 'package:mindhaven/Community/community.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityWelcomePage extends StatefulWidget {
  const CommunityWelcomePage({super.key});

  @override
  _CommunityWelcomePageState createState() => _CommunityWelcomePageState();
}

class _CommunityWelcomePageState extends State<CommunityWelcomePage> with SingleTickerProviderStateMixin {
  String? userName = 'User'; // Default name
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

      setState(() {
        userName = response?['full_name']?.split(' ')?.first ??
            user.email?.split('@')[0] ??
            'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Upper section (background #d4c8c2)
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xffd4c8c2),
                child: Stack(
                  children: [
                    // Larger 'like.png' in the center with animation
                    Center(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _animation.value),
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/images/like.png', // Ensure this image is in assets folder
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.width * 0.8,
                        ),
                      ),
                    ),
                    // Medium 'reading.png' in middle-right
                    Positioned(
                      right: 20,
                      top: MediaQuery.of(context).size.height * 0.35,
                      child: Image.asset(
                        'assets/images/reading.png', // Ensure this image is in assets folder
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: MediaQuery.of(context).size.width * 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Lower section (white background with circular top)
            Expanded(
              flex: 2, // Increase the flex value to allocate more space
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView( // Wrap the Column with SingleChildScrollView
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 20.0), // Add padding to the bottom
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Circular top decoration
                        Container(
                          width: double.infinity,
                          height: 1,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Welcome message
                        const Text(
                          'Welcome to Our Loving Community!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Our community is a place of warmth and acceptance, where everyone’s voice is valued and respected.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Start Posting button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CommunityPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff9bb068),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                          ),
                          child: const Text(
                            'Start Posting →',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}