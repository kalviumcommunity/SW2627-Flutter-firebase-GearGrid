// File generated manually based on Firebase project configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCPQ2LBLgCIZksrCAVQyI3FtG67RsHzWmo',
    appId: '1:1013613419389:web:dd18060249f4c530128a14',
    messagingSenderId: '1013613419389',
    projectId: 'geargrid-sw2627',
    authDomain: 'geargrid-sw2627.firebaseapp.com',
    storageBucket: 'geargrid-sw2627.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWkMZk8-rhauEeYaSlXTwewa-28bYuY6k',
    appId: '1:1013613419389:android:07d6aac58537eade128a14',
    messagingSenderId: '1013613419389',
    projectId: 'geargrid-sw2627',
    storageBucket: 'geargrid-sw2627.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzhPn8xnv8mmu_dBKktwFfIlyhgLmPm-U',
    appId: '1:1013613419389:ios:9d9a83ad9032987d128a14',
    messagingSenderId: '1013613419389',
    projectId: 'geargrid-sw2627',
    storageBucket: 'geargrid-sw2627.firebasestorage.app',
    iosBundleId: 'com.example.sw2627FlutterFirebaseGeargrid',
  );
}
