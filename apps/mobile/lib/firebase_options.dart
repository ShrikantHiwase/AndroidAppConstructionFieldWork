// GENERATED PLACEHOLDER — replace by running `flutterfire configure` from apps/mobile.
// Keep [FirebaseOptionsGate.isConfigured] false until real options are committed
// (google-services.json / GoogleService-Info.plist remain gitignored).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class FirebaseOptionsGate {
  /// Flip to true only after replacing this file via flutterfire configure.
  static const bool isConfigured = false;
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!FirebaseOptionsGate.isConfigured) {
      throw UnsupportedError(
        'Firebase is not configured. Run flutterfire configure '
        'and set FirebaseOptionsGate.isConfigured = true.',
      );
    }
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Dummy values so the file type-checks; unused while isConfigured == false.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:replace',
    messagingSenderId: '000000000000',
    projectId: 'replace-me',
    authDomain: 'replace-me.firebaseapp.com',
    storageBucket: 'replace-me.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:replace',
    messagingSenderId: '000000000000',
    projectId: 'replace-me',
    storageBucket: 'replace-me.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:replace',
    messagingSenderId: '000000000000',
    projectId: 'replace-me',
    storageBucket: 'replace-me.appspot.com',
    iosBundleId: 'com.rayns.constructionFieldApp',
  );
}
