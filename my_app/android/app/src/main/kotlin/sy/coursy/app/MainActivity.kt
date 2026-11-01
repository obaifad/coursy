package sy.coursy.app

import io.flutter.embedding.android.FlutterActivity

// قناة الإشعارات تُنشأ مرة واحدة في CoursyApplication (تعمل حتى عند وصول FCM والتطبيق مغلق).
class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL_ID = "coursy_default"
        const val CHANNEL_NAME = "Coursy"
    }

    // النشاط مُصدَّر (المشغّل)، وFlutter يقرأ extra اسمه "route" من أي Intent: أي تطبيق آخر كان يفتح
    // أي شاشة مباشرة متخطّياً شاشة البداية (بوابة الضيف والتحديث الإجباري). نبدأ دائماً من المسار الافتراضي.
    override fun getInitialRoute(): String? = null
}
