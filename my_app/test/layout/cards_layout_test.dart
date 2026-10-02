import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout_harness.dart';
import 'sample_data.dart';

/// فحص تخطيط كل البطاقات العامة داخل حاوياتها الحقيقية بكل المقاسات.
void main() {
  final allIssues = <LayoutIssue>[];

  setUpAll(loadAuditFonts);
  setUp(Get.reset);

  tearDownAll(() {
    // ignore: avoid_print
    print('\n===== CARDS LAYOUT REPORT (${allIssues.length} findings) =====\n${formatIssues(allIssues)}');
  });

  testWidgets('course grid (Courses tab / category / instructor)', (tester) async {
    allIssues.addAll(
      await auditScene(tester, 'course-grid', () {
        final courses = sampleCourses();
        return Builder(
          builder: (context) => GridView.builder(
            padding: EdgeInsets.all(AppLayout.horizontalPage(context)),
            gridDelegate: AppGridLayouts.courseGridFor(context),
            itemCount: courses.length,
            itemBuilder: (_, i) => CourseCard(course: courses[i], onTap: () {}),
          ),
        );
      }),
    );
  });

  testWidgets('featured course rail (Home)', (tester) async {
    allIssues.addAll(
      await auditScene(tester, 'course-featured', () {
        final courses = sampleCourses();
        return Builder(
          builder: (context) => ListView(
            children: [
              AppHorizontalListView(
                height: CourseCardMetrics.featuredCardHeight(context),
                bottomInset: AppHorizontalListView.cardShadowBottomInset,
                itemCount: courses.length,
                itemBuilder: (_, i) => SizedBox(
                  width: CourseCardMetrics.featuredCardWidth(context),
                  child: CourseCard(course: courses[i], showActionButton: false, onTap: () {}),
                ),
              ),
            ],
          ),
        );
      }),
    );
  });

  testWidgets('home mini rails (institutes, private instructors)', (tester) async {
    allIssues.addAll(
      await auditScene(tester, 'mini-rails', () {
        final institutes = sampleInstitutes();
        final instructors = sampleInstructors();
        return Builder(
          builder: (context) => ListView(
            children: [
              AppHorizontalListView(
                // نفس ارتفاع الرئيسية (home_view): 120 × تكبير الخط.
                height: 120 * CourseCardMetrics.textScaleOf(context),
                bottomInset: AppHorizontalListView.cardShadowBottomInset,
                itemCount: instructors.length,
                itemBuilder: (_, i) => PrivateInstructorMiniCard(instructor: instructors[i], onTap: () {}),
              ),
              const SizedBox(height: 16),
              AppHorizontalListView(
                height: 200,
                bottomInset: AppHorizontalListView.cardShadowBottomInset,
                itemCount: institutes.length,
                itemBuilder: (_, i) => InstituteMiniCard(institute: institutes[i], onTap: () {}),
              ),
            ],
          ),
        );
      }),
    );
  });

  testWidgets('list cards (institutes, instructors, notifications, profile)', (tester) async {
    allIssues.addAll(
      await auditScene(tester, 'list-cards', () {
        return Builder(
          builder: (context) => ListView(
            padding: EdgeInsets.all(AppLayout.horizontalPage(context)),
            children: [
              AppSectionHeader(
                title: longCourseAr,
                subtitle: longCourseEn,
                actionLabel: 'show_all'.tr,
                onAction: () {},
              ),
              const SizedBox(height: 12),
              for (final institute in sampleInstitutes()) ...[
                InstituteListCard(institute: institute, onTap: () {}),
                const SizedBox(height: 12),
              ],
              for (final instructor in sampleInstructors()) ...[
                PrivateInstructorListCard(instructor: instructor, onTap: () {}),
                const SizedBox(height: 12),
              ],
              for (final n in sampleNotifications()) ...[
                NotificationCard(
                  title: n.title,
                  subtitle: n.subtitle,
                  icon: Icons.notifications_rounded,
                  unread: !n.isRead,
                ),
                const SizedBox(height: 12),
              ],
              AppStatsRow(
                items: [
                  AppStatItem(value: '12', label: 'stat_active'.tr),
                  AppStatItem(value: '1,250', label: 'stat_completed'.tr),
                  AppStatItem(value: '3', label: 'stat_review'.tr),
                ],
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(title: 'verify_phone_title'.tr, icon: Icons.verified_user_outlined, onTap: () {}),
              ProfileMenuTile(title: longCourseAr, icon: Icons.edit_outlined, onTap: () {}),
            ],
          ),
        );
      }),
    );
  });

  testWidgets('banners and heroes', (tester) async {
    allIssues.addAll(
      await auditScene(tester, 'banners', () {
        final categories = sampleCategories();
        return ListView(
          children: [
            CategoryHeaderBanner(category: categories[1], coursesCount: 128),
            const SizedBox(height: 12),
            // في التطبيق: خلفية SliverAppBar بارتفاع ثابت (expandedHeight: 200).
            SizedBox(height: 200, child: InstituteDetailHero(institute: sampleInstitutes().first)),
            const SizedBox(height: 12),
            AppEmptyState(message: longCourseAr, subtitle: longCourseEn, icon: Icons.inbox_outlined),
          ],
        );
      }),
    );
  });
}
