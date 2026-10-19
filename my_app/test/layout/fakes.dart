import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:my_app/core/data/repositories/auth_repository.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/data/repositories/city_repository.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/data/repositories/device_repository.dart';
import 'package:my_app/core/data/repositories/enrollment_repository.dart';
import 'package:my_app/core/data/repositories/favorites_repository.dart';
import 'package:my_app/core/data/repositories/home_repository.dart';
import 'package:my_app/core/data/repositories/institute_repository.dart';
import 'package:my_app/core/data/repositories/instructor_repository.dart';
import 'package:my_app/core/data/repositories/interest_repository.dart';
import 'package:my_app/core/data/repositories/notification_repository.dart';
import 'package:my_app/core/data/repositories/payment_repository.dart';
import 'package:my_app/core/data/repositories/profile_repository.dart';
import 'package:my_app/core/data/repositories/reference_repository.dart';
import 'package:my_app/core/data/repositories/review_repository.dart';
import 'package:my_app/core/data/repositories/search_repository.dart';
import 'package:my_app/core/locale/locale_controller.dart';
import 'package:my_app/core/locale/locale_request_guard.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/favorite_model.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/core/services/favorites_service.dart';
import 'package:my_app/core/services/push_notification_service.dart';
import 'package:my_app/core/services/student_id_resolver.dart';
import 'package:my_app/core/storage/recent_search_storage.dart';
import 'package:my_app/core/storage/token_storage.dart';

import 'sample_data.dart';

PaginatedResult<T> _page<T>(List<T> items) =>
    PaginatedResult<T>(items: items, currentPage: 1, lastPage: 1, total: items.length, hasMore: false);

/// «الشبكة» الوهمية: كل طلب يمرّ من هنا فيُسجَّل اسمه، ويمكن للاختبار أن يؤخّره ([gate]) أو يُفشله
/// ([failing]) — لاختبار متى تبدأ الطلبات، وما يبقى ظاهراً حين تفشل.
abstract final class FakeApi {
  /// أسماء الطلبات بالترتيب (مثل `fetchCourseById`).
  static final List<String> calls = [];

  /// طلبات تفشل بـ [failure]؛ `*` = كلها.
  static final Set<String> failing = {};

  static ApiException failure = ApiException('fake offline', statusCode: 503);

  /// إن وُجد: كل طلب ينتظره قبل الرد (يُكمله الاختبار متى شاء).
  static Completer<void>? gate;

  static int count(String name) => calls.where((c) => c == name).length;

  static void reset() {
    calls.clear();
    failing.clear();
    failure = ApiException('fake offline', statusCode: 503);
    gate = null;
  }

  static Future<T> call<T>(String name, T Function() result) async {
    calls.add(name);
    final pending = gate;
    if (pending != null) await pending.future;
    if (failing.contains(name) || failing.contains('*')) throw failure;
    return result();
  }
}

class _Categories extends CategoryRepository {
  _Categories(super.client);
  @override
  Future<List<CategoryModel>> fetchCategories({int perPage = 50}) => FakeApi.call('fetchCategories', sampleCategories);
}

class _Interests extends InterestRepository {
  _Interests(super.client);
  @override
  Future<List<CategoryModel>> fetchInterests({int perPage = 50}) => FakeApi.call('fetchInterests', sampleCategories);
}

List<CityModel> _sampleCities() => [
  CityModel.fromJson({'id': 1, 'name_ar': 'دمشق', 'name_en': 'Damascus'}),
  CityModel.fromJson({'id': 2, 'name_ar': 'ريف دمشق - جرمانا', 'name_en': 'Rural Damascus - Jaramana'}),
  CityModel.fromJson({'id': 3, 'name_ar': 'حلب', 'name_en': 'Aleppo'}),
];

class _Cities extends CityRepository {
  _Cities(super.client);
  @override
  Future<List<CityModel>> fetchCities({int perPage = 100}) => FakeApi.call('fetchCities', _sampleCities);
  @override
  Future<CityModel> fetchCityById(int id) => FakeApi.call(
    'fetchCityById',
    () => _sampleCities().firstWhere((c) => c.id == id, orElse: () => throw ApiException('not found', statusCode: 404)),
  );
  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesByCity(int cityId, {int page = 1, int perPage = 15}) =>
      FakeApi.call('fetchInstitutesByCity', () => _page(sampleInstitutes()));
}

class _Rating extends CourseRatingService {
  _Rating(super.client);
  @override
  Future<List<CourseModel>> enrich(List<CourseModel> courses) async => courses;
  @override
  Future<List<InstituteModel>> enrichInstitutes(List<InstituteModel> institutes) async => institutes;
}

class _Courses extends CourseRepository {
  _Courses(super.client, super.rating);
  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) => FakeApi.call('fetchCoursesPage', () => _page(sampleCourses()));
  @override
  Future<List<CourseModel>> fetchCourses({Map<String, dynamic>? query}) => FakeApi.call('fetchCourses', sampleCourses);
  @override
  Future<List<CourseModel>> fetchSuggestedCourses({int limit = 10}) =>
      FakeApi.call('fetchSuggestedCourses', () => sampleCourses().reversed.toList());
  @override
  Future<List<CourseModel>> fetchInstituteCourses(int instituteId) =>
      FakeApi.call('fetchInstituteCourses', sampleCourses);
  @override
  Future<CourseModel> fetchCourseById(int id) =>
      FakeApi.call('fetchCourseById', () => sampleCourses().firstWhere((c) => c.id == id));
  @override
  Future<List<ScheduleModel>> fetchCourseSchedules(int courseId) =>
      FakeApi.call('fetchCourseSchedules', () => <ScheduleModel>[]);
  @override
  Future<int> countInstituteCourses(int instituteId) => FakeApi.call('countInstituteCourses', () => 12);
}

class _Institutes extends InstituteRepository {
  _Institutes(super.client);
  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) => FakeApi.call('fetchInstitutesPage', () => _page(sampleInstitutes()));
  @override
  Future<List<InstituteModel>> fetchInstitutes({Map<String, dynamic>? query}) =>
      FakeApi.call('fetchInstitutes', sampleInstitutes);
  @override
  Future<InstituteModel> fetchInstituteById(int id) =>
      FakeApi.call('fetchInstituteById', () => sampleInstitutes().first);
}

class _Instructors extends InstructorRepository {
  _Instructors(super.client, super.reference);
  @override
  Future<PaginatedResult<InstructorModel>> fetchInstructorsPage({
    int page = 1,
    int perPage = 15,
    bool? isPrivate,
    int? instituteId,
    String? subjectKey,
    int? specializationId,
  }) => FakeApi.call('fetchInstructorsPage', () => _page(sampleInstructors()));
  @override
  Future<List<InstructorModel>> fetchInstructors({
    int? instituteId,
    bool? isPrivate,
    String? subjectKey,
    int? specializationId,
  }) => FakeApi.call('fetchInstructors', sampleInstructors);
  @override
  Future<List<InstructorSubjectModel>> fetchInstructorSubjectFilters() => FakeApi.call(
    'fetchInstructorSubjectFilters',
    () => [
      InstructorSubjectModel(key: 'spec:1', name: 'هندسة البرمجيات والذكاء الاصطناعي', instructorsCount: 12),
      InstructorSubjectModel(key: 'spec:2', name: 'رياضيات', instructorsCount: 3),
    ],
  );
  @override
  Future<List<InstructorModel>> fetchInstructorsBySubject({required String subjectKey, bool privateOnly = true}) =>
      FakeApi.call('fetchInstructorsBySubject', sampleInstructors);
  @override
  Future<InstructorModel> fetchInstructorById(int id) => FakeApi.call(
    'fetchInstructorById',
    // معرّف غير موجود في العيّنة = 404 من الخادم (تبقى بيانات البطاقة كما هي).
    () => sampleInstructors().firstWhere(
      (i) => i.id == id,
      orElse: () => throw ApiException('not found', statusCode: 404),
    ),
  );
  @override
  Future<PaginatedResult<CourseModel>> fetchInstructorCoursesPage({
    required int instructorId,
    int page = 1,
    int perPage = 15,
  }) => FakeApi.call('fetchInstructorCoursesPage', () => _page(sampleCourses()));
}

class _Reference extends ReferenceRepository {
  _Reference(super.client);
  @override
  Future<List<NamedEntity>> fetchUniversities() async => [
    NamedEntity.fromJson({'id': 1, 'name': 'جامعة دمشق'}),
  ];
  @override
  Future<List<NamedEntity>> fetchStudentSpecializations() async => [
    NamedEntity.fromJson({'id': 1, 'name': 'هندسة المعلوماتية'}),
  ];
}

class _Home extends HomeRepository {
  _Home(super.client);
  @override
  Future<HomePayload?> fetchHomepage() => FakeApi.call(
    'fetchHomepage',
    () => HomePayload(
      courses: sampleCourses(),
      suggestedCourses: sampleCourses().reversed.toList(),
      institutes: sampleInstitutes(),
      categories: sampleCategories(),
    ),
  );
}

class _Enrollments extends EnrollmentRepository {
  _Enrollments(super.client);
  @override
  Future<PaginatedResult<EnrollmentModel>> fetchEnrollmentsPage({int page = 1, int perPage = 15}) =>
      FakeApi.call('fetchEnrollmentsPage', () => _page(sampleEnrollments()));
  @override
  Future<List<EnrollmentModel>> fetchEnrollments() => FakeApi.call('fetchEnrollments', sampleEnrollments);
}

/// تفاصيل الدفع التي يرجعها المزيّف — يضبطها كل مشهد قبل الرسم.
Map<String, dynamic> fakePaymentJson = {};

class _Payments extends PaymentRepository {
  _Payments(super.client);
  @override
  Future<PaymentDetailsModel> fetchDetails(int enrollmentId) =>
      FakeApi.call('fetchPaymentDetails', () => PaymentDetailsModel.fromJson(fakePaymentJson));
}

class _Notifications extends NotificationRepository {
  _Notifications(super.client);
  @override
  Future<PaginatedResult<NotificationModel>> fetchNotificationsPage({int page = 1, int perPage = 15}) =>
      FakeApi.call('fetchNotificationsPage', () => _page(sampleNotifications()));
  @override
  Future<List<NotificationModel>> fetchNotifications() => FakeApi.call('fetchNotifications', sampleNotifications);
  @override
  Future<void> markRead(int notificationId) => FakeApi.call('markRead', () {});
  @override
  Future<void> markAllRead() => FakeApi.call('markAllRead', () {});
}

class _Favorites extends FavoritesRepository {
  _Favorites(super.client, super.resolver);
  @override
  Future<List<FavoriteModel>> fetchMine() => FakeApi.call(
    'fetchFavorites',
    () => [
      FavoriteModel.fromJson({'id': 1, 'course_id': 1}),
      FavoriteModel.fromJson({'id': 2, 'course_id': 4}),
    ],
  );
  @override
  Future<void> removeFavorite(int favoriteId, {int? courseId}) async {}
}

class _Reviews extends ReviewRepository {
  _Reviews(super.client);
  @override
  Future<List<ReviewModel>> fetchReviews({int? courseId, int? instituteId, int? instructorId}) =>
      FakeApi.call('fetchReviews', sampleReviews);
}

class _Search extends SearchRepository {
  _Search(super.client, super.rating);
  @override
  Future<SearchResult> search({
    required String query,
    SearchScope scope = SearchScope.all,
    int limit = 12,
    int? categoryId,
    int? cityId,
    String? level,
    String? studyType,
    int? instituteId,
    bool? featured,
    bool? verified,
  }) => FakeApi.call(
    'search',
    () => SearchResult(courses: sampleCourses(), institutes: sampleInstitutes(), instructors: sampleInstructors()),
  );
}

class _Profile extends ProfileRepository {
  _Profile(super.client, super.tokens);
  @override
  Future<Map<String, dynamic>> fetchFullStudentUser() async => {
    'first_name': 'عبد الرحمن',
    'last_name': 'الخطيب الحسيني',
    'phone': '0999123456',
    'gender': 'male',
    'city_id': 2,
    'birth_date': '2000-03-05',
    'student_profile': {
      'education_level': 'Bachelor',
      'university_id': 1,
      'specialization_id': 1,
      'preferred_categories': [3, 5],
    },
  };
}

class FakeRecentSearches extends RecentSearchStorage {
  @override
  Future<void> init() async => queries.assignAll(['فلاتر', 'Business English', 'إدارة المشاريع الاحترافية']);
  @override
  Future<void> add(String query) async {}
  @override
  Future<void> clear() async => queries.clear();
}

class _StudentId extends StudentIdResolver {
  _StudentId(super.tokens, super.profile);
  @override
  Future<int> resolve() async => 1;
}

/// يسجّل كل التبعيات بنسخ وهمية — نفس ما يفعله AppBindings لكن بلا شبكة.
Future<TokenStorage> registerFakes({required bool loggedIn, required String locale}) async {
  Get.reset();
  FakeApi.reset();
  FlutterSecureStorage.setMockInitialValues({});
  // TokenStorage الحقيقي مع تخزين آمن وهمي — القيم observable كما في التطبيق (Obx يعمل كما هو).
  final tokens = Get.put(TokenStorage());
  if (loggedIn) {
    await tokens.saveSession(
      token: 'test-token',
      name: 'د. عبد الرحمن محمد الخطيب الحسيني',
      phone: '0999123456',
      verifiedPhone: false,
      studentId: 1,
    );
  }
  final client = ApiClient(tokens);
  Get.put(client);
  Get.put(LocaleRequestGuard());
  final localeController = Get.put(LocaleController());
  localeController.code.value = locale;

  final rating = Get.put<CourseRatingService>(_Rating(client));
  final profile = Get.put<ProfileRepository>(_Profile(client, tokens));
  final resolver = Get.put<StudentIdResolver>(_StudentId(tokens, profile));
  final reference = Get.put<ReferenceRepository>(_Reference(client));
  Get.put<CategoryRepository>(_Categories(client));
  Get.put<InterestRepository>(_Interests(client));
  Get.put<CityRepository>(_Cities(client));
  Get.put<CourseRepository>(_Courses(client, rating));
  Get.put<InstituteRepository>(_Institutes(client));
  Get.put<InstructorRepository>(_Instructors(client, reference));
  Get.put<HomeRepository>(_Home(client));
  Get.put<EnrollmentRepository>(_Enrollments(client));
  Get.put<NotificationRepository>(_Notifications(client));
  Get.put<PaymentRepository>(_Payments(client));
  Get.put<ReviewRepository>(_Reviews(client));
  Get.put<SearchRepository>(_Search(client, rating));
  Get.put<AuthRepository>(AuthRepository(client, tokens));
  final favoritesRepo = Get.put<FavoritesRepository>(_Favorites(client, resolver));
  Get.put(FavoritesService(favoritesRepo, tokens));
  Get.put(PushNotificationService(tokens, DeviceRepository(client)));
  final recent = Get.put<RecentSearchStorage>(FakeRecentSearches());
  await recent.init();
  return tokens;
}
