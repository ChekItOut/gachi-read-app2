// File generated based on Firebase project: gachibible-580c0
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCFIaHwEdJTr_wqAKGXPXqMUrN6CaXPbSk',
    appId: '1:70879729412:web:ce1f793a219a1d8f63a251',
    messagingSenderId: '70879729412',
    projectId: 'gachibible-580c0',
    authDomain: 'gachibible-580c0.firebaseapp.com',
    storageBucket: 'gachibible-580c0.firebasestorage.app',
    measurementId: 'G-40K5H1HMSN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBup0X44OevuNGFsuZSsH7s-O8SnKkwsyM',
    appId: '1:70879729412:android:9015d357feeeb67963a251',
    messagingSenderId: '70879729412',
    projectId: 'gachibible-580c0',
    storageBucket: 'gachibible-580c0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRgSngtzq1yw-2ycvwAyeVM0bgBsGKq6c',
    appId: '1:70879729412:ios:98316f7a3598b99263a251',
    messagingSenderId: '70879729412',
    projectId: 'gachibible-580c0',
    storageBucket: 'gachibible-580c0.firebasestorage.app',
    androidClientId: '70879729412-glg22mb0k8f47tg7hl6b2en6j7mqa31g.apps.googleusercontent.com',
    iosClientId: '70879729412-ucp02t7ap5vps8pd7kp7h80qkatfcnb6.apps.googleusercontent.com',
    iosBundleId: 'com.gachijukja.gachiReadApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBRgSngtzq1yw-2ycvwAyeVM0bgBsGKq6c',
    appId: '1:70879729412:ios:98316f7a3598b99263a251',
    messagingSenderId: '70879729412',
    projectId: 'gachibible-580c0',
    storageBucket: 'gachibible-580c0.firebasestorage.app',
    androidClientId: '70879729412-glg22mb0k8f47tg7hl6b2en6j7mqa31g.apps.googleusercontent.com',
    iosClientId: '70879729412-ucp02t7ap5vps8pd7kp7h80qkatfcnb6.apps.googleusercontent.com',
    iosBundleId: 'com.gachijukja.gachiReadApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCFIaHwEdJTr_wqAKGXPXqMUrN6CaXPbSk',
    appId: '1:70879729412:web:37ca4daee4898c0463a251',
    messagingSenderId: '70879729412',
    projectId: 'gachibible-580c0',
    authDomain: 'gachibible-580c0.firebaseapp.com',
    storageBucket: 'gachibible-580c0.firebasestorage.app',
    measurementId: 'G-9V2H2K2CZ3',
  );

}