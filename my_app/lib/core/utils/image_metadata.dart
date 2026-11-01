import 'dart:typed_data';

/// يزيل البيانات الوصفية من صورة قبل رفعها (موقع GPS، تاريخ التصوير، رقم الجهاز التسلسلي، اسم المالك).
///
/// image_picker ينسخ EXIF الأصلي كاملاً إلى الصورة المصغّرة، والصورة الشخصية يراها الآخرون في المراجعات.
/// JPEG: تُحذف مقاطع APP1 (EXIF/XMP) وAPP3–APP13 وAPP15 والتعليقات، ويبقى اتجاه الصورة فقط (وإلا ظهرت
/// صور الكاميرا مقلوبة). يبقى JFIF وملف الألوان ICC (APP2) وAdobe (APP14) لأنها تؤثر في عرض الألوان.
/// PNG: تُحذف مقاطع eXIf والنصوص والوقت. أي صيغة أخرى أو ملف تالف يُعاد كما هو.
Uint8List stripImageMetadata(Uint8List bytes) {
  try {
    if (_isJpeg(bytes)) return _stripJpeg(bytes);
    if (_isPng(bytes)) return _stripPng(bytes);
  } on _Malformed {
    return bytes;
  }
  return bytes;
}

/// اسم الملف المرفوع حسب الصيغة الفعلية (لا اسم الملف الأصلي، فقد يحمل تاريخاً أو اسم جهاز).
String avatarFileName(Uint8List bytes) => _isPng(bytes) ? 'avatar.png' : 'avatar.jpg';

class _Malformed implements Exception {}

bool _isJpeg(Uint8List b) => b.length >= 4 && b[0] == 0xFF && b[1] == 0xD8;

const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

bool _isPng(Uint8List b) {
  if (b.length < 8) return false;
  for (var i = 0; i < 8; i++) {
    if (b[i] != _pngSignature[i]) return false;
  }
  return true;
}

bool _dropJpegSegment(int marker) =>
    marker == 0xE1 || (marker >= 0xE3 && marker <= 0xED) || marker == 0xEF || marker == 0xFE;

Uint8List _stripJpeg(Uint8List b) {
  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  var i = 2;
  var orientationWritten = false;
  while (i < b.length) {
    if (i + 1 >= b.length || b[i] != 0xFF) throw _Malformed();
    final marker = b[i + 1];
    // حشو 0xFF وعلامات بلا طول.
    if (marker == 0xFF) {
      i++;
      continue;
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      out.add(b.sublist(i, i + 2));
      i += 2;
      continue;
    }
    if (i + 4 > b.length) throw _Malformed();
    final length = (b[i + 2] << 8) | b[i + 3];
    if (length < 2 || i + 2 + length > b.length) throw _Malformed();
    final end = i + 2 + length;
    // بداية بيانات الصورة: الباقي ينسخ كما هو.
    if (marker == 0xDA) {
      out.add(b.sublist(i));
      return out.toBytes();
    }
    if (_dropJpegSegment(marker)) {
      if (marker == 0xE1 && !orientationWritten) {
        final orientation = _exifOrientation(b, i + 4, end);
        if (orientation != null && orientation != 1) {
          out.add(_orientationOnlyExif(orientation));
          orientationWritten = true;
        }
      }
    } else {
      out.add(b.sublist(i, end));
    }
    i = end;
  }
  throw _Malformed();
}

/// قيمة وسم الاتجاه (0x0112) في IFD0 من مقطع EXIF، أو null.
int? _exifOrientation(Uint8List b, int start, int end) {
  const header = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]; // "Exif\0\0"
  if (end - start < 14) return null;
  for (var k = 0; k < 6; k++) {
    if (b[start + k] != header[k]) return null;
  }
  final tiff = start + 6;
  final bool little;
  if (b[tiff] == 0x49 && b[tiff + 1] == 0x49) {
    little = true;
  } else if (b[tiff] == 0x4D && b[tiff + 1] == 0x4D) {
    little = false;
  } else {
    return null;
  }
  int u16(int p) => little ? b[p] | (b[p + 1] << 8) : (b[p] << 8) | b[p + 1];
  int u32(int p) => little
      ? b[p] | (b[p + 1] << 8) | (b[p + 2] << 16) | (b[p + 3] << 24)
      : (b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3];
  final ifd = tiff + u32(tiff + 4);
  if (ifd + 2 > end) return null;
  final count = u16(ifd);
  for (var n = 0; n < count; n++) {
    final entry = ifd + 2 + n * 12;
    if (entry + 12 > end) return null;
    if (u16(entry) == 0x0112) {
      final value = u16(entry + 8);
      return value >= 1 && value <= 8 ? value : null;
    }
  }
  return null;
}

/// مقطع APP1 فيه وسم الاتجاه وحده (TIFF big-endian، IFD واحد بمدخل واحد).
List<int> _orientationOnlyExif(int orientation) => [
  0xFF, 0xE1, 0x00, 0x22, // APP1، الطول 34
  0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // Exif\0\0
  0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // MM، 42، IFD0 عند 8
  0x00, 0x01, // مدخل واحد
  0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, orientation, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, // لا IFD تالٍ
];

const _pngDroppedChunks = {'eXIf', 'tEXt', 'zTXt', 'iTXt', 'tIME'};

Uint8List _stripPng(Uint8List b) {
  final out = BytesBuilder(copy: false)..add(b.sublist(0, 8));
  var i = 8;
  while (i < b.length) {
    if (i + 12 > b.length) throw _Malformed();
    final length = (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    final end = i + 12 + length;
    if (length < 0 || end > b.length) throw _Malformed();
    final type = String.fromCharCodes(b.sublist(i + 4, i + 8));
    if (!_pngDroppedChunks.contains(type)) out.add(b.sublist(i, end));
    i = end;
    if (type == 'IEND') return out.toBytes();
  }
  throw _Malformed();
}
