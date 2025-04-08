import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Displays a persistent notification that is non-dismissible by the user.
/// It includes an action button "Stop Tracking" that will trigger an intent to stop tracking.
Future<void> showPersistentNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
  'tracking_channel', // Channel ID
  'Tracking Notifications', // Channel Name
  channelDescription: 'Your location is being tracked along the route.',
  importance: Importance.max,
  priority: Priority.high,
  ongoing: true,
  autoCancel: false,
  icon: 'ic_notification', // This should match the file name (without the extension)
  actions: <AndroidNotificationAction>[
    AndroidNotificationAction(
      'STOP_TRACKING',
      'Stop Tracking',
      showsUserInterface: true,
    ),
  ],
);


  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID.
    'Tracking Active',
    'You are being tracked along the route.',
    platformChannelSpecifics,
  );
}
