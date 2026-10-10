import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/json_parser.dart';
import 'package:my_app/core/services/app_config_service.dart';

void main() {
  setUpAll(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('ar');
  });

  group('app config', () {
    test('versions compare numerically, missing parts are zero, build suffix ignored', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.2', '1.10'), -1);
      expect(compareVersions('2.0', '1.9.9'), 1);
      expect(compareVersions('1.0.0+7', '1.0.0'), 0);
      expect(compareVersions('1.0', '1.0.1'), -1);
    });

    AppConfig config({String? min, String? latest, bool maintenance = false}) => AppConfig.fromJson({
      'android': {
        'min_version': min,
        'latest_version': latest,
        'store_url': 'https://play.google.com/store/apps/details?id=sy.coursy.app',
      },
      'maintenance': maintenance,
      'maintenance_message': null,
    }, 'android');

    test('maintenance wins, then forced update below minimum, then suggestion below latest', () {
      expect(
        decideAppConfigAction(config(min: '1.0.0', latest: '1.0.0', maintenance: true), '1.0.0'),
        AppConfigAction.maintenance,
      );
      expect(decideAppConfigAction(config(min: '1.1.0', latest: '1.2.0'), '1.0.0'), AppConfigAction.forceUpdate);
      expect(decideAppConfigAction(config(min: '1.0.0', latest: '1.2.0'), '1.0.0'), AppConfigAction.suggestUpdate);
      expect(decideAppConfigAction(config(min: '1.0.0', latest: '1.0.0'), '1.0.0'), AppConfigAction.none);
      expect(decideAppConfigAction(config(), '1.0.0'), AppConfigAction.none);
    });

    test('reads the platform block and the maintenance flag in any common form', () {
      final c = AppConfig.fromJson({
        'ios': {'min_version': '1.0.0', 'latest_version': '1.1.0', 'store_url': 'https://apps.apple.com/app/id1'},
        'maintenance': 1,
        'maintenance_message': 'صيانة',
      }, 'ios');
      expect(c.minVersion, '1.0.0');
      expect(c.storeUrl, 'https://apps.apple.com/app/id1');
      expect(c.maintenance, isTrue);
      expect(c.maintenanceMessage, 'صيانة');
    });
  });

  test('server error code is read from the error body', () {
    expect(errorCodeFromBody({'message': 'x', 'code': 'transaction_already_used'}), 'transaction_already_used');
    expect(errorCodeFromBody({'message': 'x'}), isNull);
    expect(errorCodeFromBody('html'), isNull);
  });

  test('free course shows "free"; price 0 that is not free shows "coming soon"', () {
    final free = CourseModel.fromJson({'id': 1, 'title': 'x', 'price': '0.00', 'is_free': true});
    final unpriced = CourseModel.fromJson({'id': 2, 'title': 'y', 'price': '0.00', 'is_free': false});
    expect(free.isFree, isTrue);
    expect(free.price, 'مجاني');
    expect(free.hasDiscount, isFalse);
    expect(unpriced.isFree, isFalse);
    expect(unpriced.price, '—');
  });

  test('institute contact fields are parsed and empty values ignored', () {
    final i = InstituteModel.fromJson({
      'id': 1,
      'name': 'x',
      'phone': '+963 966 449 911',
      'whatsapp': '',
      'website': 'coursy.sy',
      'facebook': null,
    });
    expect(i.phone, '+963 966 449 911');
    expect(i.whatsapp, isNull);
    expect(i.website, 'coursy.sy');
    expect(i.hasContact, isTrue);
    expect(InstituteModel.fromJson({'id': 2, 'name': 'y'}).hasContact, isFalse);
  });
}
