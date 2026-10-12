import 'package:get/get.dart';

import '../storage/token_storage.dart';
import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/root/controllers/root_controller.dart';

/// متحكّمات تبويبات الرئيسية تعيش ما عاش التطبيق (permanent) — تُنشأ عند أول استخدام فقط.
///
/// AppNavigation.goToRoot يفتح الرئيسية بـ offAllNamed وقد تكون نسخة قديمة منها تحت الصفحة الحالية
/// (ضيف يسجّل الدخول، إتمام حجز، إشعار). كان GetX يحذف المتحكّمات المرتبطة بالنسخة القديمة عند إزالتها
/// والنسخة الجديدة تستخدمها: ScrollController مُتخلّص منه، توقّف «تحميل المزيد» وتحميل كل شيء من جديد.
class RootBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RootController>()) {
      Get.put(RootController(), permanent: true);
    }
    _keep<HomeController>(() => HomeController(Get.find<TokenStorage>()));
    _keep<CoursesController>(CoursesController.new);
    _keep<InstitutesController>(InstitutesController.new);
    _keep<MyCoursesController>(MyCoursesController.new);
  }

  static void _keep<S>(S Function() create) {
    if (!Get.isRegistered<S>()) GetInstance().lazyPut<S>(create, fenix: true, permanent: true);
  }
}
