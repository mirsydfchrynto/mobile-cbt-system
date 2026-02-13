import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured yet');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyYRZwjmUMjCJ5FAWcy7A7-EhKXqmGgCc',
    appId: '1:913244224408:android:76609da069906900609ed',
    messagingSenderId: '913244224408',
    projectId: 'cbt-master-6e6a4',
    storageBucket: 'cbt-master-6e6a4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyYRZwjmUMjCJ5FAWcy7A7-EhKXqmGgCc',
    appId: '1:913244224408:ios:76609da069906900609ed',
    messagingSenderId: '913244224408',
    projectId: 'cbt-master-6e6a4',
    storageBucket: 'cbt-master-6e6a4.firebasestorage.app',
  );
}