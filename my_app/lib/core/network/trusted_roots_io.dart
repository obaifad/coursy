import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> installTrustedRoots(List<String> assets) async {
  for (final asset in assets) {
    final data = await rootBundle.load(asset);
    addTrustedRoot(SecurityContext.defaultContext, data.buffer.asUint8List());
  }
}

/// يضيف شهادة جذر (PEM) إلى [context]. false إن كانت موجودة فيه أصلاً (أنظمة أحدث تحتويها) — بلا رمي.
@visibleForTesting
bool addTrustedRoot(SecurityContext context, List<int> pem) {
  try {
    context.setTrustedCertificatesBytes(pem);
    return true;
  } on TlsException catch (e) {
    if ('${e.message} ${e.osError?.message}'.contains('CERT_ALREADY_IN_HASH_TABLE')) return false;
    rethrow;
  }
}
