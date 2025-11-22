import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1lEgwpLYjob5mb3mdLhvSYHnlfNFzPyw',
    appId: '1:1037368853288:android:bd6da7aaab62513ba0461d',
    messagingSenderId: '1037368853288',
    projectId: 'ovo-ride',
    storageBucket: 'ovo-ride.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCVz9PMd_PNqURCD2DJhdrvSdMJxT1Jcg',
    appId: '1:1037368853288:ios:2a69320170c285ada0461d',
    messagingSenderId: '1037368853288',
    projectId: 'ovo-ride',
    storageBucket: 'ovo-ride.firebasestorage.app',
    androidClientId: '1037368853288-52v19o4a590lmsfvqbh12iks1jf55727.apps.googleusercontent.com',
    iosClientId: '1037368853288-m5sd6u7i1euq16eojtdken8g3jrouru3.apps.googleusercontent.com',
    iosBundleId: 'com.ovosolution.ovoridedriver',
  );
}
