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
