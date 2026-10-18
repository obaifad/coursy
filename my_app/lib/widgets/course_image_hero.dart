import 'package:flutter/material.dart';

/// وسم انتقال صورة الدورة بين البطاقة وغلاف صفحة التفاصيل.
String courseImageHeroTag(int courseId) => 'course-image-$courseId';

/// يلفّ صورة الدورة بـ [Hero]: عند فتح الدورة تطير الصورة من البطاقة إلى غلاف الصفحة بدل القطع المفاجئ.
///
/// يُستعمل فقط حيث تظهر الدورة مرة واحدة في الشاشة (شبكة الدورات، صفحة التصنيف)، لأن وسمين متطابقين في
/// نفس المسار يرميان خطأ. بلا معرّف صالح (بطاقات الهيكل الوهمية بمعرّف 0) لا يُضاف Hero.
class CourseImageHero extends StatelessWidget {
  const CourseImageHero({super.key, required this.courseId, required this.child});

  final int courseId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (courseId <= 0) return child;
    return Hero(tag: courseImageHeroTag(courseId), child: child);
  }
}
