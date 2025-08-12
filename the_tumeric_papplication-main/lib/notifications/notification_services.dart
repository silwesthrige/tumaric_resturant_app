import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:the_tumeric_papplication/main.dart';
import 'package:the_tumeric_papplication/utils/util_functions.dart';

import 'package:timezone/timezone.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationServices {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceeBackgroundNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    await navigatorKey.currentState!
          .pushNamed('/message', arguments: notificationResponse);
    }
  
  //initialize
  static Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    //initialize plugin

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceeBackgroundNotificationResponse,
      onDidReceiveNotificationResponse:
          onDidReceeBackgroundNotificationResponse,
    );

    //request permission
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  //show a notification(instance notify)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    //define the notification details
    const NotificationDetails platformChannelSpecifications =
        NotificationDetails(
          android: AndroidNotificationDetails(
            "channelId",
            "channelName",
            importance: Importance.max,
            priority: Priority.high,
          ),
        );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifications,
    );
  }

  static Future<void> sheduleNotification({
    required String title,
    required String body,
    required DateTime sheduleDate,
  }) async {
    const NotificationDetails platformChannelSpecification =
        NotificationDetails(
          android: AndroidNotificationDetails(
            "channelId",
            "channelName",
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(sheduleDate, tz.local),
      platformChannelSpecification,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  //recurring notifications
  static Future<void> showRecurringNotification({
    required String title,
    required String body,
    required DateTime time,
    required Day day,
  }) async {
    const NotificationDetails platformChannelSpecification =
        NotificationDetails(
          android: AndroidNotificationDetails(
            "channelId",
            "channelName",
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      UtilFunctions().nextInstanceOfTime(time, day),
      platformChannelSpecification,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
    );
  }
   static Future<void> showInstantNotificationWithPayload({
    required String title,
    required String body,
    required String payload,
  }) async {
    //define the notification details
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      //define the android notification details
      android: AndroidNotificationDetails(
        "channel_Id",
        "channel_Name",
        importance: Importance.max,
        priority: Priority.high,
      ),

      //define the ios notification details
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    //show the notification
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
