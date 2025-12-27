import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' as getx;
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/firebase_options.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  ApiClient apiClient;
  PushNotificationService({required this.apiClient});

  Future<void> setupInteractedMessage() async {
    FirebaseMessaging.onBackgroundMessage(_messageHandler);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await _requestPermissions();

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      printX('onMessageOpenedApp ${message.toMap()}');
      _handleNotificationNavigation(message.data);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      printX('onMessage ${event.toMap()}');
    });

    await enableIOSNotifications();
    await registerNotificationListeners();
  }

  Future<void> registerNotificationListeners() async {
    AndroidNotificationChannel channel = androidNotificationChannel();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    var androidSettings = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var iOSSettings = const DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    var initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (message) async {
        try {
          String? payloadString = message.payload is String ? message.payload : jsonEncode(message.payload);
          printX('remarkNotification $payloadString');
          if (payloadString != null && payloadString.isNotEmpty) {
            Map<dynamic, dynamic> payloadMap = jsonDecode(payloadString);
            Map<String, String> payload = payloadMap.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );

            printX('remarkNotification ${payload['for_app']}');
            printX('remarkNotification ${payload['ride_id']}');
            
            // Handle SHARED_RIDE_STARTED notification
            if (payload['for_app'] == 'ride_details_screen' || payload.containsKey('ride_id')) {
              String? rideId = payload['ride_id']?.toString();
              if (rideId != null && rideId.isNotEmpty) {
                getx.Get.toNamed('/ride_details_screen', arguments: rideId);
                return;
              }
            }
            
            String? remark = payload['for_app'] ?? payload['app_click_action'];

            if (remark != null && remark.isNotEmpty && remark.contains('-')) {
              String route = remark.split('-')[0];
              String id = remark.split('-')[1];
              //redirect any specific page
              getx.Get.toNamed(route, arguments: id);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            printX(e.toString());
          }
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage? message) async {
      RemoteNotification? notification = message!.notification;
      AndroidNotification? android = message.notification?.android;
      printX(">>>>>> ${message.notification?.toMap()}");
      printX(">>>>>> ${android?.imageUrl}");
      if (notification != null && android != null) {
        late BigPictureStyleInformation bigPictureStyle;
        if (android.imageUrl != null) {
          Dio dio = Dio();
          Response<List<int>> response = await dio.get<List<int>>(
            android.imageUrl!,
            options: Options(
              responseType: ResponseType.bytes,
            ),
          );
          Uint8List bytes = Uint8List.fromList(response.data!);
          final String localImagePath = await _saveImageLocally(
            bytes,
          );
          bigPictureStyle = BigPictureStyleInformation(
            FilePathAndroidBitmap(localImagePath),
            contentTitle: notification.title,
            summaryText: notification.body,
          );
        }
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              enableLights: true,
              fullScreenIntent: true,
              priority: Priority.high,
              styleInformation: android.imageUrl != null ? bigPictureStyle : const BigTextStyleInformation(''),
              importance: Importance.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
      
      // Also handle navigation for foreground notifications
      _handleNotificationNavigation(message.data);
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      printX('Handling notification navigation with data: $data');
      
      // Handle SHARED_RIDE_STARTED notification
      if (data['for_app'] == 'ride_details_screen' || data.containsKey('ride_id')) {
        String? rideId = data['ride_id']?.toString();
        if (rideId != null && rideId.isNotEmpty) {
          printX('Navigating to ride details screen with ride_id: $rideId');
          getx.Get.toNamed('/ride_details_screen', arguments: rideId);
          return;
        }
      }
      
      // Handle other notification types with for_app format
      String? forApp = data['app_click_action']?.toString() ?? data['for_app']?.toString();
      if (forApp != null && forApp.isNotEmpty) {
        // If it contains a dash, it's in format "route-id"
        if (forApp.contains('-')) {
          List<String> parts = forApp.split('-');
          if (parts.length >= 2) {
            String route = parts[0];
            String id = parts.sublist(1).join('-');
            getx.Get.toNamed('/$route', arguments: id);
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        printX('Error handling notification navigation: $e');
      }
    }
  }

  Future<void> enableIOSNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  }

  AndroidNotificationChannel androidNotificationChannel() => const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        importance: Importance.high,
      );

  Future<void> _requestPermissions() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // Function to save the image locally
  Future<String> _saveImageLocally(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/notification_image.png';
    final file = File(imagePath);
    await file.writeAsBytes(bytes);
    return imagePath;
  }

  //
  Future<bool> sendUserToken() async {
    String deviceToken;
    if (apiClient.sharedPreferences.containsKey(
      SharedPreferenceHelper.fcmDeviceKey,
    )) {
      deviceToken = apiClient.sharedPreferences.getString(
            SharedPreferenceHelper.fcmDeviceKey,
          ) ??
          '';
    } else {
      deviceToken = '';
    }

    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    bool success = false;
    printD(deviceToken);
    if (deviceToken.isEmpty) {
      firebaseMessaging.getToken().then((fcmDeviceToken) async {
        success = await sendUpdatedToken(fcmDeviceToken ?? '');
      });
    } else {
      firebaseMessaging.onTokenRefresh.listen((fcmDeviceToken) async {
        if (deviceToken == fcmDeviceToken) {
          success = true;
        } else {
          apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.fcmDeviceKey,
            fcmDeviceToken,
          );
          success = await sendUpdatedToken(fcmDeviceToken);
        }
      });
    }
    return success;
  }

  Future<bool> sendUpdatedToken(String deviceToken) async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.deviceTokenEndPoint}';
    Map<String, String> map = deviceTokenMap(deviceToken);

    await apiClient.request(url, Method.postMethod, map, passHeader: true);
    return true;
  }

  Map<String, String> deviceTokenMap(String deviceToken) {
    Map<String, String> map = {'token': deviceToken.toString()};
    return map;
  }
}
