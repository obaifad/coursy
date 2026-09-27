package com.example.my_app

import io.flutter.embedding.android.FlutterActivity

// قناة الإشعارات تُنشأ مرة واحدة في CoursyApplication (تعمل حتى عند وصول FCM والتطبيق مغلق).
class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL_ID = "coursy_default"
        const val CHANNEL_NAME = "Coursy"
    }
}
