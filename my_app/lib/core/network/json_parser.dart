import 'dart:convert';

import '../models/json_helpers.dart';

/// يوحّد جسم الاستجابة (نص JSON، HTML، Map من Dio).
dynamic normalizeApiBody(dynamic body) {
  if (body == null) return null;
  if (body is String) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('<')) {
      throw const FormatException('استجابة غير JSON من الخادم');
    }
    return jsonDecode(trimmed);
  }
  return body;
}

Map<String, dynamic>? coerceMap(dynamic item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) return Map<String, dynamic>.from(item);
  return null;
}

/// استخراج بيانات من استجابات Laravel (تصفح + كائن واحد).
List<Map<String, dynamic>> extractListMap(dynamic body) {
  final normalized = normalizeApiBody(body);
  if (normalized == null) return [];

  if (normalized is List) {
    return normalized.map(coerceMap).whereType<Map<String, dynamic>>().toList();
  }

  if (normalized is Map) {
    final map = Map<String, dynamic>.from(normalized);
    for (final key in ['data', 'cities', 'items', 'results']) {
      final list = map[key];
      if (list is List) {
        return list.map(coerceMap).whereType<Map<String, dynamic>>().toList();
      }
    }
  }
  return [];
}
PaginatedMeta? extractPagination(dynamic body) {
  if (body is! Map<String, dynamic>) return null;
  if (body['current_page'] == null) return null;
  return PaginatedMeta(
    currentPage: JsonHelpers.parseInt(body['current_page']),
    lastPage: JsonHelpers.parseInt(body['last_page']),
    total: JsonHelpers.parseInt(body['total']),
    nextPageUrl: body['next_page_url']?.toString(),
  );
}

Map<String, dynamic>? extractObjectMap(dynamic body) {
  if (body is! Map<String, dynamic>) return null;
  if (body.containsKey('current_page')) return null;
  final data = body['data'];
  if (data is Map<String, dynamic> && !data.containsKey('current_page')) {
    return data;
  }
  return body;
}

String? extractToken(dynamic body) {
  if (body is! Map) return null;
  final map = Map<String, dynamic>.from(body);
  const keys = ['token', 'access_token', 'accessToken', 'plainTextToken'];
  for (final key in keys) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
  }
  final data = map['data'];
  if (data is Map) {
    final nested = Map<String, dynamic>.from(data);
    for (final key in keys) {
      final v = nested[key];
      if (v is String && v.isNotEmpty) return v;
    }
  }
  return null;
}

Map<String, dynamic>? extractUserMap(dynamic body) {
  if (body is! Map) return null;
  final map = Map<String, dynamic>.from(body);
  if (map['user'] is Map) return Map<String, dynamic>.from(map['user'] as Map);
  if (map['student'] is Map) return Map<String, dynamic>.from(map['student'] as Map);
  if (map['data'] is Map) {
    final data = Map<String, dynamic>.from(map['data'] as Map);
    if (data['user'] is Map) return Map<String, dynamic>.from(data['user'] as Map);
    if (data['student'] is Map) return Map<String, dynamic>.from(data['student'] as Map);
  }
  return null;
}

/// معرّف الطالب لجدول enrollments / favorites (ليس بالضرورة نفس user.id).
int? extractStudentId(Map<String, dynamic>? map) {
  if (map == null) return null;
  for (final key in ['student_id', 'studentId']) {
    final v = JsonHelpers.parseIntOrNull(map[key]);
    if (v != null && v > 0) return v;
  }
  if (map['student'] is Map) {
    final nested = Map<String, dynamic>.from(map['student'] as Map);
    final fromNested = extractStudentId(nested);
    if (fromNested != null) return fromNested;
  }
  if (map['student_profile'] is Map) {
    final profile = Map<String, dynamic>.from(map['student_profile'] as Map);
    final fromProfile = extractStudentId(profile);
    if (fromProfile != null) return fromProfile;
  }
  return JsonHelpers.parseIntOrNull(map['id']);
}

int? extractStudentIdFromBody(dynamic body) {
  final normalized = normalizeApiBody(body);
  if (normalized is! Map) return null;
  final map = Map<String, dynamic>.from(normalized);
  final direct = extractStudentId(map);
  if (direct != null) return direct;
  return extractStudentId(extractUserMap(normalized));
}

bool isPhoneVerified(Map<String, dynamic>? user) {
  if (user == null) return false;
  final v = user['phone_verified_at'];
  return v != null && v.toString().isNotEmpty && v.toString() != 'null';
}

/// حقول المستخدم/الطالب من استجابة الملف الشخصي أو /student/me.
Map<String, dynamic> extractProfileUserMap(dynamic body) {
  final normalized = normalizeApiBody(body);
  if (normalized is! Map) return {};

  Map<String, dynamic> map = Map<String, dynamic>.from(normalized);
  for (var depth = 0; depth < 4; depth++) {
    if (map['user'] is Map) {
      return Map<String, dynamic>.from(map['user'] as Map);
    }
    if (map['student'] is Map) {
      return Map<String, dynamic>.from(map['student'] as Map);
    }
    if (map['data'] is Map) {
      map = Map<String, dynamic>.from(map['data'] as Map);
      continue;
    }
    if (map.containsKey('first_name') || map.containsKey('phone')) {
      return map;
    }
    break;
  }
  return map;
}

String? extractUserDisplayName(dynamic body) {
  if (body is! Map) return null;
  final map = Map<String, dynamic>.from(body);
  Map<String, dynamic>? user;
  if (map['user'] is Map) {
    user = Map<String, dynamic>.from(map['user'] as Map);
  } else if (map['data'] is Map) {
    final data = Map<String, dynamic>.from(map['data'] as Map);
    if (data['user'] is Map) user = Map<String, dynamic>.from(data['user'] as Map);
    if (data['student'] is Map) user = Map<String, dynamic>.from(data['student'] as Map);
  }
  if (user == null) return null;
  final first = user['first_name']?.toString() ?? '';
  final last = user['last_name']?.toString() ?? '';
  final full = '$first $last'.trim();
  if (full.isNotEmpty) return full;
  return user['name']?.toString();
}

String messageFromErrorBody(dynamic body, {String fallback = 'حدث خطأ غير متوقع'}) {
  final fields = fieldErrorsFromBody(body);
  if (fields.isNotEmpty) return fields.values.first;
  if (body is Map) {
    final map = Map<String, dynamic>.from(body);
    if (map['message'] is String) return map['message'] as String;
  }
  return fallback;
}

Map<String, String> fieldErrorsFromBody(dynamic body) {
  if (body is! Map) return {};
  final errors = body['errors'];
  if (errors is! Map) return {};

  final result = <String, String>{};
  for (final entry in errors.entries) {
    final value = entry.value;
    if (value is List && value.isNotEmpty) {
      result[entry.key.toString()] = value.first.toString();
    } else if (value is String && value.isNotEmpty) {
      result[entry.key.toString()] = value;
    }
  }
  return result;
}

class PaginatedMeta {
  PaginatedMeta({required this.currentPage, required this.lastPage, required this.total, this.nextPageUrl});

  final int currentPage;
  final int lastPage;
  final int total;
  final String? nextPageUrl;

  bool get hasMore => nextPageUrl != null && nextPageUrl!.isNotEmpty;
}
