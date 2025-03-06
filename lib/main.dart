import 'package:flutter/material.dart';
import 'package:mindhaven/Community/community.dart';
import 'package:mindhaven/Home/breathing.dart';
import 'package:mindhaven/Home/daily_journal.dart';
import 'package:mindhaven/Home/exercise_page.dart';
import 'package:mindhaven/Home/graph.dart';
import 'package:mindhaven/Home/profile.dart';
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
import 'package:mindhaven/assessment/mood_page.dart'; // Updated to use MoodPage
import 'package:mindhaven/assessment/enter_name_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'chat/chat_provider.dart';
import 'package:mindhaven/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ivrpyicshglignfqpzhs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2cnB5aWNzaGdsaWduZnFwemhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4MzQ4MDcsImV4cCI6MjA1NjQxMDgwN30.gocb_iC5tLI5LxFAJ49Ij7NDftIvth4aYxxaupHO8c8',
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: const MyApp(),
    ),
  );
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
        colorScheme: ColorScheme.fromSwatch().copyWith(
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
        '/profile': (context) => const ProfilePage(),
        '/chat': (context) => const ChatScreen(),
        // Mapping question numbers to assessment pages
        '/mood': (context) => const MoodPage(),
        '/graph': (context) => const GraphPage(),
        '/exercises': (context) => ExercisePage(), // Create this page
        //'/chat': (context) => ChatPage(), // Create this page
        '/journal': (context) => JournalPage(), // Create this page
        '/music': (context) => ExercisePage(), // Create this page
        '/meditation': (context) => BreathingExercisePage(), // Create this page
        '/community': (context) => CommunityPage(), // Create this page
        // Create this page
        '/dashboard': (context) => GraphPage(),// Question 1: Mood
        '/question2': (context) => const QuestionPage(
          questionNumber: 2,
          questionText: 'I feel sad and low',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question3': (context) => const QuestionPage(
          questionNumber: 3,
          questionText: 'I feel disinterested in things that earlier seemed pleasurable',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question4': (context) => const QuestionPage(
          questionNumber: 4,
          questionText: 'I feel I should be (or I am being) punished',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question5': (context) => const QuestionPage(
          questionNumber: 5,
          questionText: 'I feel guilty',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question6': (context) => const QuestionPage(
          questionNumber: 6,
          questionText: 'I have difficulty making decisions',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question7': (context) => const QuestionPage(
          questionNumber: 7,
          questionText: 'I feel tired and low on energy',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question8': (context) => const QuestionPage(
          questionNumber: 8,
          questionText: 'I believe that nothing will ever work out for me',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question9': (context) => const QuestionPage(
          questionNumber: 9,
          questionText: 'I have difficulty concentrating',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question10': (context) => const QuestionPage(
          questionNumber: 10,
          questionText: 'I feel irritated',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question11': (context) => const QuestionPage(
          questionNumber: 11,
          questionText: 'I feel restless and anxious',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question12': (context) => const QuestionPage(
          questionNumber: 12,
          questionText: 'I cry (or I feel like crying)',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question13': (context) => const QuestionPage(
          questionNumber: 13,
          questionText: 'I have thoughts about ending my life',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question14': (context) => const QuestionPage(
          questionNumber: 14,
          questionText: 'I feel like a failure',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question15': (context) => const QuestionPage(
          questionNumber: 15,
          questionText: 'I feel like I am alone (or want to be alone)',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question16': (context) => const QuestionPage(
          questionNumber: 16,
          questionText: 'It takes me a lot of effort to do the smallest of things',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question17': (context) => const QuestionPage(
          questionNumber: 17,
          questionText: 'I feel helpless',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question18': (context) => const QuestionPage(
          questionNumber: 18,
          questionText: 'I don’t feel happy even when good things happen',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question19': (context) => const QuestionPage(
          questionNumber: 19,
          questionText: 'I think my life isn’t worth living',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question20': (context) => const QuestionPage(
          questionNumber: 20,
          questionText: 'I am eating significantly more (or less) than usual',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        '/question21': (context) => const QuestionPage(
          questionNumber: 21,
          questionText: 'My sleep is disturbed (unrestful or broken sleep)',
          options: {
            'Never': Icons.sentiment_satisfied,
            'Hardly ever': Icons.sentiment_neutral,
            'Some of the time': Icons.sentiment_dissatisfied,
            'Most of the time': Icons.sentiment_very_dissatisfied,
            'All the time': Icons.sentiment_very_dissatisfied,
          },
          totalQuestions: 21,
        ),
        // Add '/result' route later
      },
    );
  }
}