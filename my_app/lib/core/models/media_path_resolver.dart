/// استخراج مسارات الصور/الملفات من استجابات Laravel (نص، كائن، قائمة).
abstract final class MediaPathResolver {
  static String? extract(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final resolved = coerce(json[key]);
      if (resolved != null) return resolved;
    }
    return null;
  }

  static String? coerce(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final nestedKey in const [
        'url',
        'original_url',
        'full_url',
        'path',
        'original',
        'src',
        'file',
        'file_path',
        'image',
        'image_url',
      ]) {
        final nested = coerce(map[nestedKey]);
        if (nested != null) return nested;
      }
      return null;
    }
    if (raw is List && raw.isNotEmpty) {
      return coerce(raw.first);
    }
    final value = raw.toString().trim();
    if (value.isEmpty || value == 'null') return null;
    return value;
  }

  /// مفاتيح شائعة لصور الدورات من الداشبورد / Spatie Media / Filament.
  static const courseImageKeys = [
    'image',
    'cover_image',
    'image_url',
    'cover_image_url',
    'course_image',
    'course_image_url',
    'thumbnail',
    'thumbnail_url',
    'photo',
    'photo_url',
    'picture',
    'featured_image',
    'featured_image_url',
    'banner',
    'banner_image',
    'poster',
    'poster_url',
  ];

  static const nestedContainers = [
    'media',
    'attachments',
    'files',
    'images',
    'gallery',
    'uploads',
  ];

  static String? extractCourseImage(Map<String, dynamic> json) {
    final direct = extract(json, courseImageKeys);
    if (direct != null) return direct;

    for (final key in nestedContainers) {
      final resolved = coerce(json[key]);
      if (resolved != null) return resolved;
    }
    return null;
  }
}
