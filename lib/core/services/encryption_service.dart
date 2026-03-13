import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  /// Derive a 32-byte AES key from a plain-text password using SHA-256
  static enc.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypt raw bytes with password → returns base64-encoded cipher text
  static String encryptBytes(Uint8List data, String password) {
    final key = _deriveKey(password);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    // Prepend IV (16 bytes) before cipher bytes so we can decrypt later
    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);
    return base64.encode(combined);
  }

  /// Decrypt base64-encoded cipher text with password → returns raw bytes
  static Uint8List decryptBytes(String encodedData, String password) {
    final key = _deriveKey(password);
    final combined = base64.decode(encodedData);
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherBytes = Uint8List.fromList(combined.sublist(16));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = enc.Encrypted(cipherBytes);
    final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decryptedBytes);
  }
}
