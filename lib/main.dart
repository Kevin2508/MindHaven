import 'package:flutter/material.dart';
import 'package:mindhaven/assessment/question1.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindhaven/Splash/splash_screen.dart';
import 'package:mindhaven/login/login_page.dart';
import 'package:mindhaven/Home/home_page.dart';
import 'package:mindhaven/login/sign_up.dart';
import 'package:mindhaven/Home/score_page.dart';
import 'package:mindhaven/assessment/welcome.dart';
import 'package:mindhaven/assessment/age.dart';
import 'package:mindhaven/assessment/gender.dart';
import 'package:mindhaven/assessment/question1.dart';
import 'package:mindhaven/assessment/enter_name_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ivrpyicshglignfqpzhs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2cnB5aWNzaGdsaWduZnFwemhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4MzQ4MDcsImV4cCI6MjA1NjQxMDgwN30.gocb_iC5tLI5LxFAJ49Ij7NDftIvth4aYxxaupHO8c8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mental Health Assessment',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Urbanist',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.w300, fontFamily: 'Urbanist'),
          displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.w300, fontFamily: 'Urbanist'),
          displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.w400, fontFamily: 'Urbanist'),
          headlineMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w400, fontFamily: 'Urbanist'),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontFamily: 'Urbanist'),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, fontFamily: 'Urbanist'),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, fontFamily: 'Urbanist'),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Urbanist'),
        ),
        primaryColor: const Color(0xFF9BB168),
        colorScheme:  ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF926247),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/sign-up': (context) => const SignUpPage(),
        '/score': (context) => const ScorePage(),
        '/welcome': (context) => const WelcomePage(),
        '/EnterNamePage': (context) => const EnterNamePage(),
        // Mapping question numbers to assessment pages
        '/question1': (context) => const AgePage(), // Question 1: Age
        '/question2': (context) => const GenderPage(), // Question 2: Gender
        '/question3': (context) => const QuestionPage(
          questionNumber: 3,
          questionText: 'How often do you struggle with anxious thoughts?',
          options: {
            'Rarely': Icons.sentiment_satisfied,
            'Sometimes': Icons.sentiment_neutral,
            'Often': Icons.sentiment_dissatisfied,
            'Always': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 11,
        ),
        '/question4': (context) => const QuestionPage(
          questionNumber: 4,
          questionText:
          'Do you have trouble sleeping or experience frequent disturbances in your sleep?',
          options: {
            'Yes': Icons.bedtime,
            'No': Icons.check_circle,
            'Sometimes': Icons.adjust,
          },
          totalQuestions: 11,
        ),
        '/question5': (context) => const QuestionPage(
          questionNumber: 5,
          questionText: 'How often do you engage in physical activity or exercise?',
          options: {
            'Never': Icons.accessibility_new,
            'Rarely': Icons.directions_walk,
            'Several times a week': Icons.directions_run,
            'Daily': Icons.fitness_center,
          },
          totalQuestions: 11,
        ),
        '/question6': (context) => const QuestionPage(
          questionNumber: 6,
          questionText: 'Do you find it difficult to focus or stay motivated in your daily tasks?',
          options: {
            'Yes': Icons.remove_red_eye,
            'No': Icons.check_circle,
            'Sometimes': Icons.adjust,
          },
          totalQuestions: 11,
        ),
        '/question7': (context) => const QuestionPage(
          questionNumber: 7,
          questionText: 'How much time do you spend on social media daily?',
          options: {
            'Less than 1 hour': Icons.access_time,
            '1-3 hours': Icons.schedule,
            '4-6 hours': Icons.timer,
            'More than 6 hours': Icons.watch_later,
          },
          totalQuestions: 11,
        ),
        '/question8': (context) => const QuestionPage(
          questionNumber: 8,
          questionText: 'How often do you compare yourself to others on social media?',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Rarely': Icons.sentiment_neutral,
            'Sometimes': Icons.sentiment_dissatisfied,
            'Often': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 11,
        ),
        '/question9': (context) => const QuestionPage(
          questionNumber: 9,
          questionText:
          'Do you feel anxious or uneasy when you don’t check your phone for a long time?',
          options: {
            'Yes': Icons.phone_missed,
            'No': Icons.check_circle,
            'Sometimes': Icons.adjust,
          },
          totalQuestions: 11,
        ),
        '/question10': (context) => const QuestionPage(
          questionNumber: 10,
          questionText:
          'Do you worry about financial stability or managing expenses? ',
          options: {
            'Yes': Icons.remove_red_eye,
            'No': Icons.check_circle,
            'Sometimes': Icons.adjust,
          },
          totalQuestions: 11,
        ),
        '/question11': (context) => const QuestionPage(
          questionNumber: 11,
          questionText:
          'Are you stressed about your future career or life goals?',
          options: {
            'Yes': Icons.remove_red_eye,
            'No': Icons.check_circle,
            'Sometimes': Icons.adjust,
          },
          totalQuestions: 11,
        ),
        // Add '/result' route later
      },
    );
  }
}