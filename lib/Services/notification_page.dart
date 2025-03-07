import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:mindhaven/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize Awesome Notifications
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use null if res_app_icon is not set up
      [
        NotificationChannel(
          channelKey: 'wellness_channel',
          channelName: 'Wellness Recommendations',
          channelDescription: 'Notifications for wellness score recommendations',
          defaultColor: const Color(0xFF9BB168),
          ledColor: const Color(0xFF9BB168),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );

    // Request notification permissions
    await AwesomeNotifications().requestPermissionToSendNotifications();
    print('Notification permissions requested');
  }

  // Hardcode wellness score for demo
  Future<int> calculateWellnessScore() async {
    // Temporarily bypass Supabase for demo
    return 30; // Simulate "Low Wellness" (21-40)
  }

  // Map wellness score to recommendation category
  List<String> getRecommendations(int wellnessScore) {
    if (wellnessScore <= 20) {
      return [
        'Meditation: Try a 20-minute breathing exercise to calm your mind—head to the Exercises page.',
        'AI Chatbot: Chat with Braino now—it’s here to listen and help you through this.',
        'Journal: Write a few words about how you feel in your Daily Journal. It’s a safe space.',
        'Music Meditation: Unwind with ‘Chirping Birds’ on the Music page—it’s a treat.',
      ];
    } else if (wellnessScore <= 40) {
      return [
        'Meditation: Try a 15-minute meditation session—find it on the Meditation page.',
        'Community: Post in the Stress category—others might have advice or just relate.',
        'Photo Journal: Snap a quick photo today—sometimes a small reflection helps.',
      ];
    } else if (wellnessScore <= 60) {
      return [
        'Meditation: How about 10 minutes of yoga? Check the Exercises page.',
        'Sleep Tracking: Log your sleep tonight—let’s see if it’s affecting your mood.',
        'Positive Affirmation: Record a thought like ‘I’m doing my best’—it’s a mood booster.',
      ];
    } else if (wellnessScore <= 80) {
      return [
        'Meditation: Try a 5-minute mindfulness session—head to the Meditation page.',
        'Dashboard Review: Check your mood trends on the Dashboard—see your progress!',
        'Community: Share a positive idea in the Affinity category—you could lift someone’s day.',
      ];
    } else {
      return [
        'Meditation: Enjoy a 5-minute yoga flow to stay balanced—find it in Exercises.',
        'Music Meditation: Unwind with ‘Chirping Birds’ on the Music page—it’s a treat.',
        'Community: Post a tip in the Community—your positivity can inspire others!',
      ];
    }
  }

  // Send a notification with a recommendation
  Future<void> sendRecommendationNotification() async {
    final wellnessScore = await calculateWellnessScore();
    final recommendations = getRecommendations(wellnessScore);

    // Pick a random recommendation
    String recommendation = recommendations[DateTime.now().second % recommendations.length];

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        channelKey: 'wellness_channel',
        title: 'Wellness Score: $wellnessScore',
        body: recommendation,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF9BB168),
        backgroundColor: const Color(0xFF9BB168),
        payload: {'route': _getRouteFromRecommendation(recommendation)},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'OPEN',
          label: 'Open',
          color: const Color(0xFF9BB168),
        ),
      ],
    );
    print('Notification sent: Wellness Score: $wellnessScore, Body: $recommendation');
  }

  // Map recommendation to route for deep linking
  String _getRouteFromRecommendation(String recommendation) {
    if (recommendation.contains('Meditation') || recommendation.contains('Exercises')) {
      return '/exercises';
    } else if (recommendation.contains('AI Chatbot')) {
      return '/chat';
    } else if (recommendation.contains('Journal')) {
      return '/journal';
    } else if (recommendation.contains('Music')) {
      return '/music';
    } else if (recommendation.contains('Community')) {
      return '/community';
    } else if (recommendation.contains('Dashboard')) {
      return '/dashboard';
    } else {
      return '/home'; // Default route
    }
  }

  // Handle notification tap
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    String? route = receivedAction.payload?['route'];
    if (route != null) {
      navigatorKey.currentState?.pushNamed(route);
    }
  }
}