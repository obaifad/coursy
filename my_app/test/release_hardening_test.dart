import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/config/api_config.dart';
import 'package:my_app/core/data/repositories/device_repository.dart';
import 'package:my_app/core/models/register_payload.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/push/push_local_notifications.dart';
import 'package:my_app/core/services/push_notification_service.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/core/utils/image_metadata.dart';

/// تقوية ما قبل النشر (نتائج الفحص الأمني): مسار خارجي، حقول التسجيل، EXIF، الإشعارات، الخروج، https.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('external launch route', () {
    test('MainActivity ignores the "route" extra other apps can send', () {
      final activity = File('android/app/src/main/kotlin/sy/coursy/app/MainActivity.kt').readAsStringSync();
      expect(activity, contains('override fun getInitialRoute(): String? = null'));
    });

    test('Flutter deep linking is off on the exported activity', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        RegExp(r'android:name="flutter_deeplinking_enabled"\s*android:value="false"').hasMatch(manifest),
        isTrue,
      );
    });
  });

  test('registration body leaves role and activation to the server', () {
    final json = RegisterPayload(
      firstName: 'A',
      lastName: 'B',
      email: 'a@example.com',
      password: 'secret123',
      passwordConfirmation: 'secret123',
    ).toJson();
    expect(json.containsKey('role'), isFalse);
    expect(json.containsKey('is_active'), isFalse);
    expect(json['email'], 'a@example.com');
  });

  group('avatar metadata', () {
    final gpsMarker = 'GPS-SECRET-51.5N'.codeUnits;
    final scan = [0xFF, 0xDA, 0x00, 0x04, 0x01, 0x02, 0x11, 0x22, 0x33, 0xFF, 0xD9];

    List<int> segment(int marker, List<int> data) => [
      0xFF,
      marker,
      (data.length + 2) >> 8,
      (data.length + 2) & 0xFF,
      ...data,
    ];

    /// EXIF little-endian فيه الاتجاه ومعه نص يمثّل بيانات GPS/الرقم التسلسلي.
    List<int> exif(int orientation) => [
      ...'Exif'.codeUnits, 0, 0,
      0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00,
      0x01, 0x00,
      0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, orientation, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      ...gpsMarker,
    ];

    final jfif = segment(0xE0, [...'JFIF'.codeUnits, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0]);
    final icc = segment(0xE2, [...'ICC_PROFILE'.codeUnits, 0, 1, 1]);

    Uint8List jpeg(int orientation) => Uint8List.fromList([
      0xFF, 0xD8,
      ...jfif,
      ...segment(0xE1, exif(orientation)),
      ...icc,
      ...segment(0xED, [...'Photoshop 3.0'.codeUnits, ...gpsMarker]),
      ...segment(0xFE, gpsMarker),
      ...scan,
    ]);

    bool containsSeq(List<int> haystack, List<int> needle) {
      outer:
      for (var i = 0; i + needle.length <= haystack.length; i++) {
        for (var j = 0; j < needle.length; j++) {
          if (haystack[i + j] != needle[j]) continue outer;
        }
        return true;
      }
      return false;
    }

    test('JPEG loses EXIF, IPTC and comments but keeps colour data, pixels and orientation', () {
      final out = stripImageMetadata(jpeg(6));
      expect(containsSeq(out, gpsMarker), isFalse);
      expect(containsSeq(out, jfif), isTrue);
      expect(containsSeq(out, icc), isTrue);
      expect(containsSeq(out, scan), isTrue);
      // APP1 جديد فيه الاتجاه 6 فقط (وإلا ظهرت صورة الكاميرا مقلوبة).
      expect(containsSeq(out, [0xFF, 0xE1, 0x00, 0x22]), isTrue);
      expect(containsSeq(out, [0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x06]), isTrue);
    });

    test('upright JPEG gets no EXIF segment at all', () {
      final out = stripImageMetadata(jpeg(1));
      expect(out.contains(0xE1), isFalse);
      expect(out.length, 2 + jfif.length + icc.length + scan.length);
    });

    test('PNG loses eXIf and text chunks', () {
      List<int> chunk(String type, List<int> data) => [
        0, 0, data.length >> 8, data.length & 0xFF,
        ...type.codeUnits,
        ...data,
        0, 0, 0, 0,
      ];
      final ihdr = chunk('IHDR', List.filled(13, 1));
      final idat = chunk('IDAT', [9, 9, 9]);
      final iend = chunk('IEND', []);
      final png = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        ...ihdr,
        ...chunk('eXIf', gpsMarker),
        ...chunk('tEXt', gpsMarker),
        ...idat,
        ...iend,
      ]);
      final out = stripImageMetadata(png);
      expect(containsSeq(out, gpsMarker), isFalse);
      expect(out.length, 8 + ihdr.length + idat.length + iend.length);
      expect(avatarFileName(out), 'avatar.png');
    });

    test('unknown or truncated files are returned untouched', () {
      final other = Uint8List.fromList([1, 2, 3, 4]);
      expect(stripImageMetadata(other), same(other));
      final truncated = Uint8List.fromList(jpeg(6).sublist(0, 30));
      expect(stripImageMetadata(truncated), same(truncated));
      expect(avatarFileName(other), 'avatar.jpg');
    });
  });

  group('notification payload', () {
    test('a server value containing &key= cannot redirect the tap', () {
      final payload = PushLocalNotifications.encodePayload({
        'type': 'enrollment_approved',
        'course_id': 5,
        'title': 'Hi&course_id=999',
      });
      final data = PushLocalNotifications.decodePayload(payload);
      expect(data['course_id'], '5');
      expect(data['title'], 'Hi&course_id=999');
      expect(data.length, 3);
    });

    test('a pushed message is encoded the same way', () {
      const message = RemoteMessage(data: {'title': 'T', 'body': 'B&course_id=9', 'course_id': '3'});
      final parsed = PushLocalNotifications.parseRemoteMessage(message)!;
      expect(PushLocalNotifications.decodePayload(parsed.payload)['course_id'], '3');
    });
  });

  group('local notification channel', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <MethodCall>[];

    // في الاختبار لا يسجّل Flutter تنفيذ Android للمكتبة؛ نسجّله ليمرّ كل استدعاء من القناة الوهمية.
    setUpAll(AndroidFlutterLocalNotificationsPlugin.registerWith);

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'initialize' || call.method == 'areNotificationsEnabled') return true;
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('notification text is private on the lock screen', () async {
      await PushLocalNotifications.showRaw(id: 1, title: 'تم قبول تسجيلك', body: 'كورس', requirePermission: false);
      final show = calls.lastWhere((c) => c.method == 'show');
      final specifics = (show.arguments as Map)['platformSpecifics'] as Map;
      expect(specifics['visibility'], NotificationVisibility.private.index);
    });

    group('session end', () {
      late TokenStorage tokens;
      late _FakeMessaging messaging;
      late _RecordingDevices devices;
      late PushNotificationService service;

      setUp(() async {
        Get.reset();
        FlutterSecureStorage.setMockInitialValues({});
        tokens = Get.put(TokenStorage());
        messaging = _FakeMessaging();
        devices = _RecordingDevices(ApiClient(tokens));
        service = PushNotificationService(tokens, devices, messaging: messaging);
      });

      test('after a 401 the token is already gone, so the FCM token itself is deleted', () async {
        await service.onLogout();
        expect(devices.unregistered, isEmpty);
        expect(messaging.deletes, 1);
        expect(calls.map((c) => c.method), contains('cancelAll'));
      });

      test('a normal logout unregisters first, then deletes the FCM token', () async {
        await tokens.saveSession(token: 'auth-1', name: 'S', studentId: 1);
        await service.onLogout();
        expect(devices.unregistered, ['fcm-1']);
        expect(messaging.deletes, 1);
        expect(messaging.order, ['getToken', 'deleteToken']);
      });
    });
  });

  group('release API base URL', () {
    test('release ignores a non-https override', () {
      expect(ApiConfig.resolveBaseUrl('http://10.0.0.5:8000/api', release: true), 'https://coursy.sy/api');
    });

    test('release keeps an https override', () {
      expect(ApiConfig.resolveBaseUrl('https://staging.coursy.sy/api', release: true), 'https://staging.coursy.sy/api');
    });

    test('debug may use a local http server', () {
      expect(ApiConfig.resolveBaseUrl('http://127.0.0.1:8787/api', release: false), 'http://127.0.0.1:8787/api');
      expect(ApiConfig.resolveBaseUrl('', release: true), 'https://coursy.sy/api');
    });
  });
}

class _FakeMessaging extends Fake implements FirebaseMessaging {
  int deletes = 0;
  final order = <String>[];

  @override
  Future<String?> getToken({String? vapidKey, String? serviceWorkerScriptPath}) async {
    order.add('getToken');
    return 'fcm-1';
  }

  @override
  Future<void> deleteToken() async {
    order.add('deleteToken');
    deletes++;
  }
}

class _RecordingDevices extends DeviceRepository {
  _RecordingDevices(super.client);

  final unregistered = <String>[];

  @override
  Future<void> unregisterDeviceToken(String deviceToken) async => unregistered.add(deviceToken);
}
