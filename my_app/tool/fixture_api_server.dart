// خادم API محلي ببيانات ثابتة لاختبار التطبيق على المحاكيات بلا الخادم الحقيقي (قياس الأداء، الرجوع،
// حالات الشبكة السيئة) — النتائج قابلة للتكرار ولا تتأثر بالشبكة.
//
//   dart run tool/fixture_api_server.dart [--port 8787]
//   flutter drive ... --dart-define=API_BASE_URL=http://10.0.2.2:8787/api   (10.0.2.2 = المضيف من المحاكي)
//
// يحاكي أشكال ردود Laravel التي يقرؤها التطبيق (data / current_page / last_page / total)، ويولّد صور PNG
// بحجم صور حقيقية (1200×800) كي يُقاس فكّ الصور أيضاً.
//
// حقن الأعطال للطلبات التالية (من المضيف أو adb):
//   curl "http://127.0.0.1:8787/__control?mode=slow&delay_ms=4000"
//   الأنماط: ok | slow | fail500 | timeout | malformed | empty | html403
// السجل: GET /__log يعرض عدد الطلبات لكل مسار.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

String _mode = 'ok';
int _delayMs = 0;
final Map<String, int> _hits = {};

Future<void> main(List<String> args) async {
  final portIndex = args.indexOf('--port');
  final port = portIndex >= 0 && args.length > portIndex + 1 ? int.parse(args[portIndex + 1]) : 8787;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('fixture API on http://0.0.0.0:$port/api  (emulator: http://10.0.2.2:$port/api)');
  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest req) async {
  final path = req.uri.path;
  final q = req.uri.queryParameters;
  try {
    if (path == '/__control') {
      _mode = q['mode'] ?? _mode;
      _delayMs = int.tryParse(q['delay_ms'] ?? '') ?? (_mode == 'slow' ? 3000 : 0);
      return _json(req, {'mode': _mode, 'delay_ms': _delayMs});
    }
    if (path == '/__log') return _json(req, _hits);
    if (path.startsWith('/storage/img/')) return _image(req, path);
    if (!path.startsWith('/api/')) return _json(req, {'message': 'not found'}, status: 404);

    final route = path.substring(4); // يبدأ بـ /
    _hits[route] = (_hits[route] ?? 0) + 1;

    if (_delayMs > 0) await Future<void>.delayed(Duration(milliseconds: _delayMs));
    switch (_mode) {
      case 'timeout':
        await Future<void>.delayed(const Duration(seconds: 90));
      case 'fail500':
        return _json(req, {'message': 'Server Error'}, status: 500);
      case 'html403':
        req.response
          ..statusCode = 403
          ..headers.contentType = ContentType.html;
        req.response.write('<!DOCTYPE html><html><body>Checking your browser before accessing</body></html>');
        return req.response.close();
      case 'malformed':
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"data": [ {"id": 1, "title_ar": ');
        return req.response.close();
      case 'empty':
        return _json(req, _route(route, q, empty: true));
    }
    final body = _route(route, q);
    if (body == null) return _json(req, {'message': 'Not Found'}, status: 404);
    return _json(req, body);
  } catch (e) {
    return _json(req, {'message': 'fixture error: $e'}, status: 500);
  }
}

Future<void> _json(HttpRequest req, Object? body, {int status = 200}) {
  req.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  return req.response.close();
}

// ---------------------------------------------------------------- data

const _cityNames = [
  ('دمشق', 'Damascus'),
  ('ريف دمشق - جرمانا', 'Rural Damascus - Jaramana'),
  ('حلب', 'Aleppo'),
  ('حمص', 'Homs'),
  ('اللاذقية', 'Latakia'),
  ('طرطوس', 'Tartus'),
];
const _categoryNames = [
  ('البرمجة وتطوير التطبيقات', 'Programming'),
  ('اللغات', 'Languages'),
  ('التصميم', 'Design'),
  ('إدارة الأعمال', 'Business & Management'),
  ('المحاسبة', 'Accounting'),
  ('الشبكات', 'Networking'),
  ('الذكاء الاصطناعي', 'Artificial Intelligence'),
  ('التسويق الرقمي', 'Digital Marketing'),
  ('التصوير', 'Photography'),
  ('المهارات الشخصية', 'Soft Skills'),
];
const _specNames = [
  ('الرياضيات', 'Mathematics'),
  ('الفيزياء', 'Physics'),
  ('اللغة الإنجليزية', 'English'),
  ('هندسة البرمجيات والذكاء الاصطناعي', 'Software Engineering and Artificial Intelligence'),
  ('الكيمياء', 'Chemistry'),
  ('اللغة الفرنسية', 'French'),
];

Map<String, dynamic> _city(int i) => {'id': i + 1, 'name_ar': _cityNames[i].$1, 'name_en': _cityNames[i].$2};

final _cities = [for (var i = 0; i < _cityNames.length; i++) _city(i)];
final _categories = [
  for (var i = 0; i < _categoryNames.length; i++)
    {'id': i + 1, 'name_ar': _categoryNames[i].$1, 'name_en': _categoryNames[i].$2, 'courses_count': 4 + i},
];
final _specializations = [
  for (var i = 0; i < _specNames.length; i++)
    {'id': i + 1, 'type': 'instructor', 'name_ar': _specNames[i].$1, 'name_en': _specNames[i].$2},
];

final _institutes = [
  for (var i = 0; i < 15; i++)
    {
      'id': i + 1,
      'name_ar': i.isEven ? 'المعهد العالي للتدريب المهني والتقني رقم ${i + 1}' : 'أكاديمية المهارات ${i + 1}',
      'name_en': i.isEven ? 'Higher Institute for Vocational Training ${i + 1}' : 'Skills Academy ${i + 1}',
      'description_ar': 'معهد تدريب معتمد يقدّم دورات مهنية وتقنية بإشراف مدرّبين ذوي خبرة.',
      'description_en': 'An accredited training institute offering professional and technical courses.',
      'average_rating': (3.5 + (i % 5) * 0.3).toStringAsFixed(2),
      'courses_count': 0,
      'is_verified': i % 3 == 0 ? 1 : 0,
      'city_id': (i % _cities.length) + 1,
      'city': _cities[i % _cities.length],
      'logo': 'storage/img/${100 + i}.png',
      'cover_image': 'storage/img/${200 + i}.png',
      'phone': '0912345${(100 + i).toString()}',
      'whatsapp': '963912345${(100 + i).toString()}',
      'address': 'شارع ${i + 1}، ${_cityNames[i % _cityNames.length].$1}',
    },
];

String _futureDate(int days) => DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

final _courses = [
  for (var i = 0; i < 40; i++)
    () {
      final inst = _institutes[i % _institutes.length];
      final cat = _categories[i % _categories.length];
      final long = i % 4 == 0;
      return <String, dynamic>{
        'id': i + 1,
        'title_ar': long
            ? 'دورة احترافية شاملة في تطوير تطبيقات الهاتف المحمول رقم ${i + 1}'
            : 'دورة ${cat['name_ar']} ${i + 1}',
        'title_en': long
            ? 'Comprehensive Professional Course in Mobile App Development ${i + 1}'
            : '${cat['name_en']} course ${i + 1}',
        'description_ar': 'وصف الدورة: محتوى عملي ومشاريع تطبيقية وشهادة معتمدة في نهاية الدورة.',
        'description_en': 'Course description: hands-on content, projects and a certificate at the end.',
        'price': '${(i % 6 + 1) * 250000}',
        if (i % 3 == 0) 'discount_price': '${(i % 6 + 1) * 200000}',
        'level': ['beginner', 'intermediate', 'advanced'][i % 3],
        'study_type': ['in_person', 'online', 'hybrid'][i % 3],
        'duration_hours': 20 + (i % 5) * 20,
        'sessions_count': 8 + i % 12,
        'current_students': (i * 3) % 25,
        'max_students': 30,
        'average_rating': (3.6 + (i % 5) * 0.3).toStringAsFixed(2),
        'reviews_count': i % 7,
        'is_featured': i < 6 ? 1 : 0,
        'start_date': _futureDate(10 + i),
        'end_date': _futureDate(60 + i),
        'registration_deadline': _futureDate(5 + i),
        'category_id': cat['id'],
        'category': {'id': cat['id'], 'name_ar': cat['name_ar'], 'name_en': cat['name_en']},
        'institute_id': inst['id'],
        'institute': inst,
        'image': 'storage/img/${i % 24}.png',
      };
    }(),
];

final _instructors = [
  for (var i = 0; i < 24; i++)
    {
      'id': i + 1,
      'name_ar': i % 5 == 0 ? 'د. عبد الرحمن محمد الخطيب الحسيني ${i + 1}' : 'المدرّس ${i + 1}',
      'name_en': i % 5 == 0 ? 'Dr. Abdulrahman Mohammad Al-Khatib Al-Husseini ${i + 1}' : 'Instructor ${i + 1}',
      'bio_ar': 'خبرة طويلة في التدريس الخصوصي والتحضير للامتحانات.',
      'bio_en': 'Long experience in private tutoring and exam preparation.',
      'specialization_id': (i % _specializations.length) + 1,
      'specialization': _specializations[i % _specializations.length],
      'experience_years': 3 + i % 15,
      'is_private': 1,
      'gender': i.isEven ? 'male' : 'female',
      'session_price': '${(i % 4 + 1) * 25000}',
      if (i % 3 != 0) 'image': 'storage/img/${300 + i}.png',
    },
];

List<Map<String, dynamic>> _reviews(int n) => [
  for (var i = 0; i < n; i++)
    {
      'id': i + 1,
      'rating': 3 + i % 3,
      'comment': 'تجربة ممتازة ومحتوى مفيد جداً، أنصح بها.',
      'student_id': 1000 + i,
      'student': {'id': 1000 + i, 'name': 'طالب ${i + 1}'},
      'created_at': '2026-09-${(10 + i).toString().padLeft(2, '0')}T10:00:00Z',
    },
];

Map<String, dynamic> _paginate(List<Map<String, dynamic>> all, Map<String, String> q) {
  final perPage = int.tryParse(q['per_page'] ?? '') ?? 15;
  final page = int.tryParse(q['page'] ?? '') ?? 1;
  final start = (page - 1) * perPage;
  final items = start >= all.length ? <Map<String, dynamic>>[] : all.sublist(start, min(all.length, start + perPage));
  final last = max(1, (all.length / perPage).ceil());
  return {'current_page': page, 'last_page': last, 'per_page': perPage, 'total': all.length, 'data': items};
}

Map<String, dynamic>? _byId(List<Map<String, dynamic>> list, String id) {
  final n = int.tryParse(id);
  for (final item in list) {
    if (item['id'] == n) return item;
  }
  return null;
}

bool _matches(Map<String, dynamic> item, String query) {
  final text = '${item['title_ar'] ?? ''} ${item['title_en'] ?? ''} ${item['name_ar'] ?? ''} ${item['name_en'] ?? ''}';
  return text.toLowerCase().contains(query.toLowerCase());
}

Object? _route(String route, Map<String, String> q, {bool empty = false}) {
  final seg = route.split('/').where((s) => s.isNotEmpty).toList();
  List<Map<String, dynamic>> pick(List<Map<String, dynamic>> all) => empty ? <Map<String, dynamic>>[] : all;

  switch (seg) {
    case ['homepage']:
      return {
        'data': {
          'featured_courses': pick(_courses.take(10).toList()),
          'latest_courses': pick(_courses.reversed.take(10).toList()),
          'institutes': pick(_institutes.take(8).toList()),
          'categories': pick(_categories),
          'cities': pick(_cities),
        },
      };
    case ['app', 'config']:
      return {'data': <String, dynamic>{}};
    case ['courses']:
      var list = _courses;
      if (q['category_id'] != null) list = list.where((c) => '${c['category_id']}' == q['category_id']).toList();
      if (q['institute_id'] != null) list = list.where((c) => '${c['institute_id']}' == q['institute_id']).toList();
      return _paginate(pick(list), q);
    case ['courses', final id]:
      final c = _byId(_courses, id);
      return c == null ? null : {'data': c};
    case ['courses', _, 'reviews'] || ['instructors', _, 'reviews'] || ['institutes', _, 'reviews'] || ['reviews']:
      return {'data': pick(_reviews(4))};
    case ['course-schedules']:
      return {'data': <Object>[]};
    case ['institutes']:
      return _paginate(pick(_institutes), q);
    case ['institutes', final id]:
      final i = _byId(_institutes, id);
      return i == null ? null : {'data': i};
    case ['institutes', final id, 'courses']:
      return _paginate(pick(_courses.where((c) => '${c['institute_id']}' == id).toList()), q);
    case ['instructors']:
      var list = _instructors;
      if (q['specialization_id'] != null) {
        list = list.where((i) => '${i['specialization_id']}' == q['specialization_id']).toList();
      }
      return _paginate(pick(list), q);
    case ['instructors', final id]:
      final i = _byId(_instructors, id);
      return i == null ? null : {'data': i};
    case ['instructors', final id, 'courses']:
      final n = int.tryParse(id) ?? 1;
      return _paginate(pick([for (var k = 0; k < 6; k++) _courses[(n + k * 5) % _courses.length]]), q);
    case ['categories']:
      return {'data': pick(_categories)};
    case ['categories', final id]:
      final c = _byId(_categories, id);
      return c == null ? null : {'data': c};
    case ['cities']:
      return {'data': pick(_cities)};
    case ['cities', final id]:
      final c = _byId(_cities, id);
      return c == null ? null : {'data': c};
    case ['cities', final id, 'institutes']:
      return _paginate(pick(_institutes.where((i) => '${i['city_id']}' == id).toList()), q);
    case ['specializations']:
      return _paginate(pick(_specializations), q);
    case ['search']:
      final text = q['q'] ?? q['query'] ?? q['search'] ?? '';
      bool hit(Map<String, dynamic> m) => text.isEmpty || _matches(m, text);
      return {
        'data': {
          'courses': pick(_courses.where(hit).take(12).toList()),
          'institutes': pick(_institutes.where(hit).take(12).toList()),
          'instructors': pick(_instructors.where(hit).take(12).toList()),
        },
      };
    case ['universities'] || ['tags']:
      return {'data': <Object>[]};
  }
  return null;
}

// ---------------------------------------------------------------- images

final Map<String, Uint8List> _imageCache = {};

Future<void> _image(HttpRequest req, String path) async {
  final bytes = _imageCache.putIfAbsent(path, () {
    final seed = path.hashCode;
    final small = path.contains('/1') && path.length <= 21; // شعارات المعاهد (100..114) أصغر
    return _gradientPng(small ? 512 : 1200, small ? 512 : 800, seed);
  });
  req.response
    ..headers.contentType = ContentType('image', 'png')
    ..headers.set('Cache-Control', 'max-age=86400')
    ..add(bytes);
  await req.response.close();
}

/// PNG حقيقي بأبعاد صور حقيقية (تدرّج لوني) — مُرمَّز يدوياً بلا حزم خارجية.
Uint8List _gradientPng(int w, int h, int seed) {
  final r0 = 60 + (seed & 0x7f), g0 = 40 + ((seed >> 7) & 0x7f), b0 = 120 + ((seed >> 14) & 0x7f);
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // بلا مرشّح
    final row = Uint8List(w * 3);
    for (var x = 0; x < w; x++) {
      row[x * 3] = (r0 + x * 120 ~/ w) & 0xff;
      row[x * 3 + 1] = (g0 + y * 120 ~/ h) & 0xff;
      row[x * 3 + 2] = (b0 + (x + y) * 60 ~/ (w + h)) & 0xff;
    }
    raw.add(row);
  }
  Uint8List chunk(String type, List<int> data) {
    final typeBytes = ascii.encode(type);
    final out = BytesBuilder()
      ..add(_u32(data.length))
      ..add(typeBytes)
      ..add(data)
      ..add(_u32(_crc32([...typeBytes, ...data])));
    return out.toBytes();
  }

  final ihdr = BytesBuilder()
    ..add(_u32(w))
    ..add(_u32(h))
    ..add([8, 2, 0, 0, 0]); // 8 بت، RGB
  return (BytesBuilder()
        ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        ..add(chunk('IHDR', ihdr.toBytes()))
        ..add(chunk('IDAT', ZLibEncoder(level: 6).convert(raw.toBytes())))
        ..add(chunk('IEND', const [])))
      .toBytes();
}

List<int> _u32(int v) => [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
