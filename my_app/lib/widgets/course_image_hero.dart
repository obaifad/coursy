import 'package:flutter/material.dart';

/// وسم انتقال صورة الدورة بين البطاقة وغلاف صفحة التفاصيل.
String courseImageHeroTag(int courseId) => 'course-image-$courseId';

/// عرض فك صورة الدورة بالبكسل: واحد للبطاقة والغلاف (عرض الشاشة بحدّ أقصى 720)، فيتشاركان مدخل كاش
/// الصور نفسه — الغلاف يجد الصورة مفكوكة جاهزة عند هبوط Hero بدل فكّها ثانية وإظهارها بتلاشٍ.
int courseImageCacheWidth(BuildContext context) {
  final px = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
  return px.clamp(320, 720).round();
}

/// يلفّ صورة الدورة بـ [Hero]: عند فتح الدورة تطير الصورة من البطاقة إلى غلاف الصفحة بدل القطع المفاجئ.
///
/// يُستعمل فقط حيث تظهر الدورة مرة واحدة في الشاشة (شبكة الدورات، صفحة التصنيف)، لأن وسمين متطابقين في
/// نفس المسار يرميان خطأ. بلا معرّف صالح (بطاقات الهيكل الوهمية بمعرّف 0) لا يُضاف Hero.
///
/// الطيران بخط مستقيم (لا قوس) وبزوايا تنتقل تدريجياً من [cardRadius] إلى الغلاف المربّع، فلا تبدو
/// الصورة مقصوصة الزوايا فجأة ولا تقفز عند البداية والنهاية.
class CourseImageHero extends StatelessWidget {
  const CourseImageHero({super.key, required this.courseId, required this.child, this.cardRadius = 24});

  final int courseId;
  final Widget child;
  final double cardRadius;

  @override
  Widget build(BuildContext context) {
    if (courseId <= 0) return child;
    return Hero(
      tag: courseImageHeroTag(courseId),
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
        final source = (direction == HeroFlightDirection.push ? toContext : fromContext).widget as Hero;
        return AnimatedBuilder(
          animation: animation,
          builder: (_, shuttle) => ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius * (1 - animation.value.clamp(0.0, 1.0))),
            child: shuttle,
          ),
          child: source.child,
        );
      },
      child: child,
    );
  }
}
