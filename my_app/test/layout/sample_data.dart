import 'package:my_app/core/models/app_models.dart';

/// بيانات تجريبية متعمّدة الطول/التنوّع لكشف مشاكل التخطيط.

const longCourseAr = 'دورة احترافية شاملة في تطوير تطبيقات الهاتف المحمول باستخدام فلاتر ودارت من الصفر حتى الاحتراف';
const longCourseEn =
    'Comprehensive Professional Course in Mobile App Development with Flutter and Dart from Zero to Hero';

Map<String, dynamic> _institute({int id = 2, bool long = false}) => {
  'id': id,
  'name_ar': long ? 'المعهد العالي للتدريب المهني والتقني وتطوير المهارات الرقمية' : 'أكاديمية المهارات',
  'name_en': long ? 'Higher Institute for Vocational, Technical and Digital Skills Training' : 'Skills Academy',
  'average_rating': '4.40',
  'courses_count': 12,
  'is_verified': 1,
  'city': {
    'id': 1,
    'name_ar': long ? 'ريف دمشق - جرمانا' : 'دمشق',
    'name_en': long ? 'Rural Damascus - Jaramana' : 'Damascus',
  },
};

List<CourseModel> sampleCourses() => [
  CourseModel.fromJson({
    'id': 1,
    'title_ar': longCourseAr,
    'title_en': longCourseEn,
    'price': '1500000',
    'discount_price': '1250000',
    'level': 'intermediate',
    'study_type': 'hybrid',
    'duration_hours': 120,
    'current_students': 28,
    'max_students': 30,
    'average_rating': '4.75',
    'is_featured': 1,
    'category': {'id': 3, 'name_ar': 'البرمجة', 'name_en': 'Programming'},
    'institute': _institute(long: true),
  }),
  CourseModel.fromJson({
    'id': 2,
    'title_ar': 'إنجليزي أعمال',
    'title_en': 'Business English',
    'price': '300000',
    'level': 'beginner',
    'study_type': 'online',
    'sessions_count': 16,
    'current_students': 4,
    'max_students': 20,
    'category': {'id': 4, 'name_ar': 'اللغات', 'name_en': 'Languages'},
    'institute': _institute(),
  }),
  CourseModel.fromJson({'id': 3, 'title_ar': 'تصميم', 'title_en': 'Design', 'price': '0', 'institute': _institute()}),
  CourseModel.fromJson({
    'id': 4,
    'title_ar': 'إدارة المشاريع الاحترافية PMP مع التحضير الكامل للامتحان الدولي',
    'title_en': 'Professional Project Management (PMP) with Full International Exam Preparation',
    'price': '12500000',
    'discount_price': '9999000',
    'level': 'advanced',
    'study_type': 'offline',
    'duration_hours': 40,
    'current_students': 0,
    'max_students': 25,
    'average_rating': '3.2',
    'registration_deadline': '2020-01-01',
    'category': {'id': 5, 'name_ar': 'الأعمال والإدارة', 'name_en': 'Business & Management'},
    'institute': _institute(long: true),
  }),
];

List<InstituteModel> sampleInstitutes() => [
  InstituteModel.fromJson(_institute(long: true)),
  InstituteModel.fromJson(_institute(id: 3)),
];

List<InstructorModel> sampleInstructors() => [
  InstructorModel.fromJson({
    'id': 10,
    'name_ar': 'د. عبد الرحمن محمد الخطيب الحسيني',
    'name_en': 'Dr. Abdulrahman Mohammad Al-Khatib Al-Husseini',
    'specialization_ar': 'هندسة البرمجيات والذكاء الاصطناعي',
    'specialization_en': 'Software Engineering and Artificial Intelligence',
    'experience_years': 15,
    'hourly_price': '75000',
    'is_private': 1,
    'institutes': [_institute(long: true)],
  }),
  InstructorModel.fromJson({
    'id': 11,
    'name_ar': 'سارة',
    'name_en': 'Sara',
    'specialization_ar': 'رياضيات',
    'specialization_en': 'Math',
    'is_private': 1,
  }),
];

List<CategoryModel> sampleCategories() => [
  CategoryModel.fromJson({'id': 3, 'name_ar': 'البرمجة', 'name_en': 'Programming', 'courses_count': 24}),
  CategoryModel.fromJson({
    'id': 5,
    'name_ar': 'الأعمال والإدارة والتسويق الرقمي',
    'name_en': 'Business, Management & Digital Marketing',
    'courses_count': 128,
  }),
  CategoryModel.fromJson({'id': 4, 'name_ar': 'اللغات', 'name_en': 'Languages', 'courses_count': 3}),
];

List<NotificationModel> sampleNotifications() => [
  NotificationModel.fromJson({
    'id': 1,
    'title': 'تمت الموافقة على تسجيلك في $longCourseAr',
    'body': 'يمكنك الآن متابعة جدول الدورة والتواصل مع المعهد لإتمام إجراءات الدفع قبل موعد البدء المحدد.',
    'type': 'enrollment_approved',
    'is_read': 0,
    'created_at': '2026-09-20T10:00:00Z',
  }),
  NotificationModel.fromJson({'id': 2, 'title': 'تذكير', 'body': 'غداً', 'type': 'reminder', 'is_read': 1}),
];

List<EnrollmentModel> sampleEnrollments() {
  final courses = sampleCourses();
  return [
    EnrollmentModel(id: 1, status: 'pending', paymentStatus: 'unpaid', courseId: 1, course: courses[0]),
    EnrollmentModel(id: 2, status: 'approved', paymentStatus: 'paid', courseId: 2, course: courses[1]),
    EnrollmentModel(id: 3, status: 'rejected', paymentStatus: 'unpaid', courseId: 4, course: courses[3]),
    EnrollmentModel(id: 4, status: 'completed', paymentStatus: 'paid', courseId: 3, courseTitle: 'تصميم'),
  ];
}

List<ReviewModel> sampleReviews() => [
  ReviewModel(
    id: 1,
    rating: 5,
    comment:
        'دورة ممتازة جداً، المدرّب متمكن والشرح واضح والأمثلة عملية. أنصح بها لكل من يريد دخول مجال تطوير التطبيقات.',
    studentName: 'محمد عبد الله الأحمد',
    studentId: 7,
  ),
  ReviewModel(id: 2, rating: 3, comment: '', studentName: 'Sara', studentId: 8),
];

List<ScheduleModel> sampleSchedules() => [
  ScheduleModel(id: 1, dayOfWeek: 'saturday', startTime: '16:00:00', endTime: '18:30:00'),
  ScheduleModel(id: 2, dayOfWeek: 'wednesday', startTime: '09:00:00', endTime: '11:00:00'),
];
