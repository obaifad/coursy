import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// فتح روابط خارجية (خرائط، هاتف…) بشكل موثوق على Android/iOS/Web.
abstract final class ExternalLauncher {
  static Future<bool> openMaps({required double lat, required double lng}) async {
    final googleMaps = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (kIsWeb) {
      return _tryLaunch(googleMaps);
    }

    final candidates = <Uri>[
      Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      googleMaps,
      Uri.parse('comgooglemaps://?q=$lat,$lng'),
    ];

    for (final uri in candidates) {
      if (await _tryLaunch(uri)) return true;
    }

    Get.snackbar('error'.tr, 'open_maps_failed'.tr);
    return false;
  }

  static Future<bool> openPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^\d+]+'), '');
    if (normalized.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: normalized);
    return _tryLaunch(uri);
  }

  /// محادثة واتساب. الأرقام السورية المحلية (09…) تتحول إلى الصيغة الدولية (9639…).
  static Future<bool> openWhatsApp(String phone) async {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '963${digits.substring(1)}';
    if (digits.isEmpty) return false;
    return openWebPage('https://wa.me/$digits');
  }

  /// صفحة ويب في المتصفح، مع رسالة إن تعذّر فتحها. الرابط بلا بروتوكول يُفتح بـ https.
  static Future<bool> openWebPage(String url) async {
    final trimmed = url.trim();
    final full = trimmed.startsWith('http://') || trimmed.startsWith('https://') ? trimmed : 'https://$trimmed';
    if (await _tryLaunch(Uri.parse(full))) return true;
    Get.snackbar('error'.tr, 'open_link_failed'.tr);
    return false;
  }

  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
    } catch (_) {
      return false;
    }
  }
}
