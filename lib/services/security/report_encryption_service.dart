import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

// Top-level so compute() can spawn it across an isolate.
Uint8List _pbkdf2Derive(List<dynamic> args) {
  final passphrase = args[0] as String;
  final salt       = args[1] as Uint8List;
  final derivator  = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(salt, 100000, 32)); // 100k iterations, 32-byte key
  return derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
}

class WrongPassphraseException implements Exception {
  const WrongPassphraseException();
  @override
  String toString() => 'Incorrect passphrase';
}

/// AES-256-GCM encryption for report summaries, keyed by a user passphrase.
///
/// The passphrase is NEVER stored. A random 16-byte PBKDF2 salt and a small
/// AES-256-GCM–encrypted verification token are stored in flutter_secure_storage
/// so the unlock path can confirm the correct passphrase before touching data.
///
/// The 256-bit AES key lives only in memory (_cachedKey) for the current app
/// session. App restart or a new device always requires re-entering the passphrase.
///
/// Wire format: "enc:v1:" + base64( nonce[12] + ciphertext + gcm_tag[16] )
/// Backward compatibility: values without the prefix are returned unchanged.
class ReportEncryptionService {
  ReportEncryptionService._();
  static final instance = ReportEncryptionService._();

  static const _saltKey    = 'll_rpt_salt_v2';
  static const _verifyKey  = 'll_rpt_verify_v2';
  static const _encPrefix  = 'enc:v1:';
  static const _nonceLen   = 12;
  static const _verifyText = 'lifelink_reports_v1';

  /// Returned by [decrypt] when the service is locked, so the UI can show a
  /// placeholder rather than crash.
  static const lockedPlaceholder = '__report_locked__';

  static const _storage = FlutterSecureStorage();

  // In-memory session key — never written to disk.
  Uint8List? _cachedKey;

  bool get isUnlocked => _cachedKey != null;

  /// Returns true if a passphrase has been set on this device.
  Future<bool> hasPassphrase() async =>
      await _storage.read(key: _saltKey) != null;

  /// First-time setup: generates salt, derives key via PBKDF2, stores the
  /// salt and a verification token, caches the key for this session.
  Future<void> setPassphrase(String passphrase) async {
    final salt = Uint8List.fromList(
      List.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final key = await compute(_pbkdf2Derive, [passphrase, salt]);
    final verifyToken = _encryptRaw(key, _verifyText);
    await _storage.write(key: _saltKey,   value: base64Encode(salt));
    await _storage.write(key: _verifyKey, value: verifyToken);
    _cachedKey = key;
  }

  /// Derives key from [passphrase] + stored salt, verifies against the stored
  /// token, then caches the key for this session.
  /// Throws [WrongPassphraseException] if the passphrase is incorrect.
  Future<void> unlock(String passphrase) async {
    final saltB64     = await _storage.read(key: _saltKey);
    final verifyToken = await _storage.read(key: _verifyKey);
    if (saltB64 == null || verifyToken == null) {
      throw const WrongPassphraseException();
    }
    final key = await compute(_pbkdf2Derive, [passphrase, base64Decode(saltB64)]);
    try {
      final result = _decryptRaw(key, verifyToken);
      if (result != _verifyText) throw const WrongPassphraseException();
    } catch (_) {
      throw const WrongPassphraseException();
    }
    _cachedKey = key;
  }

  /// Clears the in-memory key (locked state for the next session).
  void lock() => _cachedKey = null;

  /// Encrypts [plaintext]. Throws [StateError] if the service is locked.
  Future<String> encrypt(String plaintext) async {
    final key = _cachedKey;
    if (key == null) throw StateError('Report encryption service is locked');
    return _encryptRaw(key, plaintext);
  }

  /// Decrypts an "enc:v1:…" value.
  /// Returns [value] unchanged if it has no prefix (legacy plaintext row).
  /// Returns [lockedPlaceholder] if the service is locked.
  /// Throws [WrongPassphraseException] if the GCM tag fails (wrong key).
  Future<String> decrypt(String value) async {
    if (!value.startsWith(_encPrefix)) return value;
    final key = _cachedKey;
    if (key == null) return lockedPlaceholder;
    try {
      return _decryptRaw(key, value);
    } catch (_) {
      throw const WrongPassphraseException();
    }
  }

  bool isEncrypted(String value) => value.startsWith(_encPrefix);

  // ── Synchronous AES-256-GCM helpers (key already in hand) ────────────────

  String _encryptRaw(Uint8List keyBytes, String plaintext) {
    final key       = enc.Key(keyBytes);
    final iv        = enc.IV.fromSecureRandom(_nonceLen);
    final encrypted = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm))
        .encrypt(plaintext, iv: iv);
    final combined  = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return '$_encPrefix${base64Encode(combined)}';
  }

  String _decryptRaw(Uint8List keyBytes, String value) {
    final key      = enc.Key(keyBytes);
    final combined = base64Decode(value.substring(_encPrefix.length));
    final iv       = enc.IV(Uint8List.fromList(combined.sublist(0, _nonceLen)));
    final cipher   = enc.Encrypted(Uint8List.fromList(combined.sublist(_nonceLen)));
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm))
        .decrypt(cipher, iv: iv);
  }
}
