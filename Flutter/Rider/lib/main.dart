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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Force recompile comment - Update 3 (Revert to original structure)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase init error: $e');
  }

  await ApiClient.init();
  Map<String, Map<String, String>> languages = await di_service.init();

  MyUtils.allScreen();
  MyUtils().stopLandscape();
  AudioUtils();

  try {
    await PushNotificationService(apiClient: Get.find()).setupInteractedMessage();
  } catch (e) {
    printX(e);
  }

  HttpOverrides.global = MyHttpOverrides();
  RunningRideService.instance.setIsRunning(false);

  tz.initializeTimeZones();
  
  try {
    GoogleMapsFlutterAndroid().warmup();
  } catch(e) {
    print('Google Maps warmup error: $e');
  }

  runApp(OvoApp(languages: languages));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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
    MyUtils.precacheImagesFromPathList(context, [MyImages.backgroundImage, MyImages.logoWhite]);
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
          getPages: RouteHelper.routes, // Using static routes list
          locale: localizeController.locale,
          translations: Messages(languages: widget.languages),
          fallbackLocale: Locale(
            Environment.defaultLanguageCode,
            Environment.defaultCountryCode,
          ),
        ),
      ),
    );
  }
}
