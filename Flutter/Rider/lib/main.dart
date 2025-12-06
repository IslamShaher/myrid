import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/theme/light/light_theme.dart';
import 'package:ovorideuser/core/theme/dark/dark_theme.dart';
import 'package:ovorideuser/core/di_service/di_services.dart' as di_service;
import 'package:ovorideuser/data/controller/common/theme_controller.dart';
import 'package:ovorideuser/data/controller/localization/localization_controller.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/packages/flutter_toast/flutter_toast.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Force recompile comment - Update 1
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase init error: $e');
  }

  await di_service.init();
  
  // HttpOverrides.global = MyHttpOverrides();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetBuilder<LocalizationController>(
          builder: (localizeController) {
            return GetMaterialApp(
              title: Environment.appName,
              debugShowCheckedModeBanner: false,
              defaultTransition: Transition.noTransition,
              transitionDuration: const Duration(milliseconds: 200),
              theme: themeController.darkTheme ? darkTheme : lightTheme,
              locale: localizeController.locale,
              translations: Messages(languages: localizeController.languages),
              fallbackLocale: Locale(
                Environment.defaultLanguageCode,
                Environment.defaultCountryCode,
              ),
              initialRoute: RouteHelper.splashScreen,
              getPages: RouteHelper.routes,
              navigatorKey: Get.key,
              builder: (context, widget) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                  child: Stack(
                    children: [
                      widget!,
                      // Toast overlay
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
