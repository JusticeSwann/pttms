// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// This function displays a persistent notification that is non-dismissible by the user.
/// It includes an action button "Stop Tracking" that will trigger an intent to stop tracking.
Future<void> showPersistentNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'tracking_channel', // Channel ID
    'Tracking Notifications', // Channel Name
    channelDescription: 'Your location is being tracked along the route.',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true, // Makes the notification non-dismissible by swiping.
    autoCancel: false,
    // Adding an action button (on Android 8.0+ this should work)
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'STOP_TRACKING', // A unique identifier for this action.
        'Stop Tracking', // Button label.
        showsUserInterface: true, // Optionally bring the app to the foreground.
        // Additional configuration for the action can go here.
      ),
    ],
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    'Tracking Active',
    'You are being tracked along the route.',
    platformChannelSpecifics,
  );
}
