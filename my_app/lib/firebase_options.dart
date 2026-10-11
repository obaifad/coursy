// Firebase configuration for Coursy.
// IMPORTANT: projectId must match the backend FCM project (coursy-ec580).
// Replace this file + google-services.json from Firebase Console if mismatched.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web in this app.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not supported on this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6FHxS0Hm6DjhMa7F9_WGDS2beSU_NA6Y',
    appId: '1:1066276389507:android:a85041adc70d39698a91b6',
    messagingSenderId: '1066276389507',
    projectId: 'coursy-ec580',
    storageBucket: 'coursy-ec580.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPQvfD92olsmk2jKjv0euUxM1LmzIAXng',
    appId: '1:1066276389507:ios:a707e2f6efff796b8a91b6',
    messagingSenderId: '1066276389507',
    projectId: 'coursy-ec580',
    storageBucket: 'coursy-ec580.firebasestorage.app',
    iosBundleId: 'sy.coursy.app',
  );
}
