import 'dart:io';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/theme/light/light.dart';
import 'package:ovorideuser/core/utils/audio_utils.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/services/running_ride_service.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/data/services/push_notification_service.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/messages.dart';
import 'package:ovorideuser/data/controller/localization/localization_controller.dart';
import 'package:toastification/toastification.dart';
import 'core/di_service/di_services.dart' as di_service;
import 'data/services/api_client.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

//APP ENTRY POINT
Future<void> main() async {
  // Ensures that widget binding is initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the API client for network communication
  await ApiClient.init();

  // Load and initialize localization/language support
  Map<String, Map<String, String>> languages = await di_service.init();

  // Configure app UI to support all screen sizes
  MyUtils.allScreen();

  // Lock device orientation to portrait mode
  MyUtils().stopLandscape();

  // Initialize audio utilities (e.g., background music, sound effects)
  AudioUtils();

  try {
    // Initialize push notification service and handle interaction messages
    await PushNotificationService(apiClient: Get.find()).setupInteractedMessage();
  } catch (e) {
    // Print error to console if FCM setup fails
    printX(e);
  }

  // Override HTTP settings (e.g., SSL certificate handling)
  HttpOverrides.global = MyHttpOverrides();

  // Set running ride status to false at app launch
  RunningRideService.instance.setIsRunning(false);

  tz.initializeTimeZones();
  GoogleMapsFlutterAndroid().warmup();
  // Launch the main application with loaded languages
  runApp(OvoApp(languages: languages));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => false;
  }
}

class OvoApp extends StatefulWidget {
  final Map<String, Map<String, String>> languages;

  const OvoApp({super.key, required this.languages});

  @override
  State<OvoApp> createState() => _OvoAppState();
}

class _OvoAppState extends State<OvoApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyUtils.precacheImagesFromPathList(context, [MyImages.backgroundImage, MyImages.logoWhite, MyImages.noDataImage]);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) => ToastificationWrapper(
        config: ToastificationConfig(maxToastLimit: 10),
        child: GetMaterialApp(
          title: Environment.appName,
          debugShowCheckedModeBanner: false,
          theme: lightThemeData,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
          initialRoute: RouteHelper.splashScreen,
          getPages: RouteHelper().routes,
          locale: localizeController.locale,
          translations: Messages(languages: widget.languages),
          fallbackLocale: Locale(
            localizeController.locale.languageCode,
            localizeController.locale.countryCode,
          ),
        ),
      ),
    );
  }
}
