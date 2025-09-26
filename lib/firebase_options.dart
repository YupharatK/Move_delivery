// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // 🔽🔽🔽 นำค่าจากไฟล์ google-services.json มาเติมตรงนี้ 🔽🔽🔽
        return const FirebaseOptions(
          apiKey:
              "AIzaSyByZlPuRZycBCBEN1MiChpkHo1SLU2Wa0o", // หาจาก "api_key": [{ "current_key": "..." }]
          appId:
              "1:887581273899:android:a2aa1696014de5c2351f6e", // คือ App ID ที่เห็นในหน้าเว็บ
          messagingSenderId:
              "887581273899", // หาจาก "project_info": { "project_number": "..." }
          projectId:
              "move-delivery-677f7", // หาจาก "project_info": { "project_id": "..." }
          storageBucket:
              "move-delivery-677f7.firebasestorage.app", // หาจาก "project_info": { "storage_bucket": "..." }
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
