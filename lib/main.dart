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
import 'package:mindhaven/assessment/mood_page.dart';
import 'package:mindhaven/assessment/enter_name_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'chat/chat_provider.dart';
import 'package:mindhaven/chat/chat_screen.dart';
import 'package:mindhaven/Services/notification_page.dart';
// Declare the global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  // Initialize notifications
  await NotificationService().initialize();

  // Set up notification action handler
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationService.onActionReceivedMethod,
  );

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
      navigatorKey: navigatorKey, // Assign the global navigator key
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
        '/mood': (context) => const MoodPage(),
        '/graph': (context) => const GraphPage(),
        '/exercises': (context) => ExercisePage(),
        '/journal': (context) => JournalPage(),
        '/music': (context) => ExercisePage(),
        '/meditation': (context) => BreathingExercisePage(),
        '/community': (context) => CommunityPage(),
        '/dashboard': (context) => GraphPage(),
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
        // ... (rest of the routes remain the same)
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
      },
    );
  }
}