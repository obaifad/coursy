part of '../design_system.dart';

/// بديل صورة المدرّس (لا صورة أو فشل تحميلها): الحرفان الأولان من اسمه على خلفية بنفسجية خفيفة، وأيقونة
/// شخص محايدة إن لم يُعرف الاسم. يملأ المساحة التي يعطيها الأب، والأب يقصّها (دائرة أو مربع مدوّر).
///
/// [onDark] فوق تدرّج الهوية: نص أبيض على خلفية بيضاء شفافة.
class InstructorPlaceholder extends StatelessWidget {
  const InstructorPlaceholder({super.key, required this.name, this.onDark = false});

  final String? name;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final initials = instructorInitials(name);
    final foreground = onDark ? Colors.white : AppColors.primaryInk;
    return ColoredBox(
      color: onDark ? Colors.white.withValues(alpha: 0.16) : AppColors.primary.withValues(alpha: 0.08),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          if (initials.isEmpty) {
            return Center(
              child: Icon(
                Icons.person_outline_rounded,
                size: side * 0.46,
                color: foreground.withValues(alpha: onDark ? 0.9 : 0.6),
              ),
            );
          }
          return Center(
            child: Text(
              initials,
              maxLines: 1,
              // الحجم يتبع المساحة لا تكبير خط النظام: الحروف جزء من الصورة.
              textScaler: TextScaler.noScaling,
              style: AppFonts.tajawal(fontSize: side * 0.34, fontWeight: FontWeight.w700, color: foreground, height: 1),
            ),
          );
        },
      ),
    );
  }
}

/// ألقاب تُتجاهل قبل أخذ الحروف («د. سامر» → «س»).
const _nameTitles = {
  'د', 'دكتور', 'الدكتور', 'دكتورة', 'الدكتورة', 'أ', 'ا', 'أد', 'الأستاذ', 'الاستاذ', 'أستاذ', 'استاذ', //
  'الأستاذة', 'الاستاذة', 'أستاذة', 'م', 'مهندس', 'المهندس', 'مهندسة', 'المهندسة', //
  'dr', 'prof', 'mr', 'mrs', 'ms', 'eng', 'teacher',
};

/// أول حرف من أول اسم وآخره: «عبد الرحمن الخطيب» → «ع‌خ». بين الحرفين فاصل منع الوصل (ZWNJ) كي لا
/// يتّصل الحرفان العربيان فيصيرا كلمة. «ال» التعريف لا يُعدّ حرفاً («الحسيني» → «ح»).
String instructorInitials(String? name) {
  final words = (name ?? '')
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r'[^\p{L}]', unicode: true), ''))
      .where((w) => w.isNotEmpty && !_nameTitles.contains(w.toLowerCase()))
      .toList();
  if (words.isEmpty) return '';

  String initial(String word) {
    final stripped = word.length > 3 && word.startsWith('ال') ? word.substring(2) : word;
    return stripped.characters.first.toUpperCase();
  }

  final first = initial(words.first);
  return words.length == 1 ? first : '$first‌${initial(words.last)}';
}
