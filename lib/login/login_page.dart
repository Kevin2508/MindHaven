import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindhaven/login/sign_up.dart';

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, size.height * 0.7)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkAuthState();
  }

  void _setupAuthListener() async {
    final supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      print('Auth state changed: $event, Session: ${session != null}');
      if (event == AuthChangeEvent.signedIn && mounted) {
        print('User signed in');
        bool isFirstTime = await _isFirstTimeUser(supabase.auth.currentUser!.id);
        if (isFirstTime && mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        } else if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(Duration.zero);
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    print('Checking initial auth state: ${session != null}');
    if (session != null && mounted) {
      bool isFirstTime = await _isFirstTimeUser(supabase.auth.currentUser!.id);
      if (isFirstTime && mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<bool> _isFirstTimeUser(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response == null;
    } catch (e) {
      print('Error checking first-time user: $e');
      return true;
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final supabase = Supabase.instance.client;
      print('Starting Google Sign-In');
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.mindhaven://login-callback/',
      );
      print('Google Sign-In initiated, waiting for redirect');
    } catch (e) {
      _showError('Google Sign-In failed: ${e.toString()}');
      print('Google Sign-In error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: OrientationBuilder(
            builder: (context, orientation) {
              return Column(
                children: [
                  ClipPath(
                    clipper: BottomCurveClipper(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      color: const Color(0xff9BB168),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: const TextStyle(color: Colors.black),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xff9BB168)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.black),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xff9BB168)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        ElevatedButton(
                          onPressed: _handleEmailSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF926247),
                            minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                        RichText(
                          text: TextSpan(
                            text: 'Don\'t have an account? ',
                            style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Urbanist'),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Sign Up',
                                style: const TextStyle(
                                  fontFamily: 'Urbanist',
                                  color: Colors.orange,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                        RichText(
                          text: TextSpan(
                            text: 'Forgot Password?',
                            style: const TextStyle(
                              fontFamily: 'Urbanist',
                              color: Colors.orange,
                              decoration: TextDecoration.underline,
                              fontSize: 16,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              // TODO: Add forgot password functionality
                            },
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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}