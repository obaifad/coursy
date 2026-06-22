import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين آمن للجلسة — Keychain / Android Keystore (لا يُنسخ مع Auto Backup).
class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
                migrateWithBackup: false,
                storageNamespace: 'com.coursy.auth',
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
              webOptions: WebOptions(
                dbName: 'CoursyAuthSession',
              ),
            );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<Map<String, String>> readAll() => _storage.readAll();
}
