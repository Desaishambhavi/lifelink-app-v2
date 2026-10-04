import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-GCM encryption for health report summaries.
///
/// The 256-bit key is generated once on first use and stored in
/// hardware-backed secure storage (Android Keystore / iOS Keychain).
/// Each encryption call produces a fresh 12-byte nonce so the same
/// plaintext always produces different ciphertext — that is the nonce's job.
///
/// Stored wire format:
///   "enc:v1:" + base64( nonce[12] || ciphertext || gcm_tag[16] )
///
/// The "enc:v1:" prefix makes decryption backward-compatible: rows written
/// before encryption was introduced have no prefix and are returned as-is.
class ReportEncryptionService {
  static const _keyStorageKey = 'll_report_key_v1';
  static const _encPrefix = 'enc:v1:';
  static const _nonceLength = 12; // 96-bit nonce — GCM standard

  static const _storage = FlutterSecureStorage();

  /// Returns the stored AES-256 key, or generates and persists a new one.
  Future<Key> _getOrCreateKey() async {
    final stored = await _storage.read(key: _keyStorageKey);
    if (stored != null) return Key(base64Decode(stored));
    final bytes = Uint8List.fromList(
      List.generate(32, (_) => Random.secure().nextInt(256)),
    );
    await _storage.write(key: _keyStorageKey, value: base64Encode(bytes));
    return Key(bytes);
  }

  /// Encrypts [plaintext] and returns an "enc:v1:…" tagged string.
  Future<String> encrypt(String plaintext) async {
    final key = await _getOrCreateKey();
    final iv = IV.fromSecureRandom(_nonceLength);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Combine nonce + ciphertext (which already includes the 16-byte GCM tag).
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return '$_encPrefix${base64Encode(combined)}';
  }

  /// Decrypts an "enc:v1:…" string back to plaintext.
  /// Returns [value] unchanged when it has no prefix (legacy plaintext row).
  Future<String> decrypt(String value) async {
    if (!value.startsWith(_encPrefix)) return value;
    final key = await _getOrCreateKey();
    final combined = base64Decode(value.substring(_encPrefix.length));
    final iv = IV(Uint8List.fromList(combined.sublist(0, _nonceLength)));
    final cipher = Encrypted(Uint8List.fromList(combined.sublist(_nonceLength)));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt(cipher, iv: iv);
  }

  /// Returns true when [value] carries the encryption prefix.
  bool isEncrypted(String value) => value.startsWith(_encPrefix);
}
