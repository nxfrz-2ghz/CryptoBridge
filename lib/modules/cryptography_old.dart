import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';


class KeyPair {
  final SimpleKeyPair privateKey;
  final SimplePublicKey publicKey;

  const KeyPair({required this.privateKey, required this.publicKey});
}


Future<KeyPair> generateKeyPair() async {
  final algorithm = X25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();

  return KeyPair(
    privateKey: keyPair,
    publicKey: publicKey,
  );
}

Future<SecretKey> deriveSharedSecret({
  required SimpleKeyPair myPrivateKey,
  required SimplePublicKey theirPublicKey,
}) async {
  final algorithm = X25519();

  final sharedSecret = await algorithm.sharedSecretKey(
    keyPair: myPrivateKey,
    remotePublicKey: theirPublicKey,
  );

  // Дополнительно хешируем через HKDF для получения ключа нужной длины
  // и защиты от потенциальных слабостей в сыром секрете
  final hkdf = Hkdf(
    hmac: Hmac(Sha256()),
    outputLength: 32, // 256 бит — ключ для AES-256
  );

  return hkdf.deriveKey(
    secretKey: sharedSecret,
    info: utf8.encode('messenger-v1'), // контекст, можно менять
  );
}


/// Экспортирует публичный ключ в байты для отправки собеседнику.
Future<Uint8List> exportPublicKey(SimplePublicKey publicKey) async {
  return Uint8List.fromList(publicKey.bytes);
}

/// Импортирует публичный ключ из байт, полученных от собеседника.
Future<SimplePublicKey> importPublicKey(Uint8List bytes) async {
  return SimplePublicKey(bytes, type: KeyPairType.x25519);
}

class EncryptedMessage {
  final Uint8List ciphertext; // зашифрованный текст
  final Uint8List nonce;      // одноразовое число (случайное, не секретное)
  final Uint8List mac;        // код аутентификации (защита от подделки)

  const EncryptedMessage({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  /// Сериализация в Base64-строку для передачи через любой транспорт
  String toBase64() {
    final combined = {
      'c': base64Encode(ciphertext),
      'n': base64Encode(nonce),
      'm': base64Encode(mac),
    };
    return base64Encode(utf8.encode(jsonEncode(combined)));
  }

  /// Десериализация из Base64-строки
  static EncryptedMessage fromBase64(String encoded) {
    final json = jsonDecode(utf8.decode(base64Decode(encoded)));
    return EncryptedMessage(
      ciphertext: base64Decode(json['c'] as String),
      nonce:      base64Decode(json['n'] as String),
      mac:        base64Decode(json['m'] as String),
    );
  }
}


// ─────────────────────────────────────────────
//  Шифрование
// ─────────────────────────────────────────────

/// Шифрует текстовое сообщение с помощью общего секретного ключа.
///
/// Используется AES-256-GCM:
/// - AES-256 — симметричное шифрование (быстрое)
/// - GCM — режим, который одновременно шифрует И проверяет целостность
///
/// Каждый раз генерируется новый случайный nonce — это важно,
/// повторное использование nonce сломает безопасность.
///
/// Пример:
///   final encrypted = await encryptMessage(sharedKey, 'Привет!');
///   final str = encrypted.toBase64(); // отправляем через транспорт
Future<EncryptedMessage> encryptMessage(
    SecretKey sharedKey,
    String plaintext,
    ) async {
  final algorithm = AesGcm.with256bits();

  // Генерируем случайный nonce (12 байт для AES-GCM)
  final nonce = algorithm.newNonce();

  final secretBox = await algorithm.encrypt(
    utf8.encode(plaintext),
    secretKey: sharedKey,
    nonce: nonce,
  );

  return EncryptedMessage(
    ciphertext: Uint8List.fromList(secretBox.cipherText),
    nonce:      Uint8List.fromList(secretBox.nonce),
    mac:        Uint8List.fromList(secretBox.mac.bytes),
  );
}

// ─────────────────────────────────────────────
//  Дешифровка
// ─────────────────────────────────────────────

/// Расшифровывает сообщение с помощью общего секретного ключа.
///
/// Если сообщение было подделано или ключ неверный —
/// выбросит SecretBoxAuthenticationError.
///
/// Пример:
///   final encrypted = EncryptedMessage.fromBase64(receivedStr);
///   final plaintext = await decryptMessage(sharedKey, encrypted);
Future<String> decryptMessage(
    SecretKey sharedKey,
    EncryptedMessage encrypted,
    ) async {
  final algorithm = AesGcm.with256bits();

  final secretBox = SecretBox(
    encrypted.ciphertext,
    nonce: encrypted.nonce,
    mac: Mac(encrypted.mac),
  );

  final plainBytes = await algorithm.decrypt(
    secretBox,
    secretKey: sharedKey,
  );

  return utf8.decode(plainBytes);
}

// ─────────────────────────────────────────────
//  Пример использования
// ─────────────────────────────────────────────

Future<void> main() async {
  print('=== Генерация ключей ===\n');

  // Алиса и Боб независимо генерируют свои ключи
  final aliceKeys = await generateKeyPair();
  final bobKeys   = await generateKeyPair();

  final alicePublicBytes = await exportPublicKey(aliceKeys.publicKey);
  final bobPublicBytes   = await exportPublicKey(bobKeys.publicKey);

  print('Публичный ключ Алисы: ${base64Encode(alicePublicBytes)}');
  print('Публичный ключ Боба:  ${base64Encode(bobPublicBytes)}\n');

  // Обмениваются публичными ключами (открыто, через сервер)
  final aliceImportedBobKey   = await importPublicKey(bobPublicBytes);
  final bobImportedAliceKey   = await importPublicKey(alicePublicBytes);

  print('=== Диффи-Хеллман: вычисление общего секрета ===\n');

  // Каждый вычисляет общий секрет независимо
  final aliceSharedSecret = await deriveSharedSecret(
    myPrivateKey:   aliceKeys.privateKey,
    theirPublicKey: aliceImportedBobKey,
  );

  final bobSharedSecret = await deriveSharedSecret(
    myPrivateKey:   bobKeys.privateKey,
    theirPublicKey: bobImportedAliceKey,
  );

  // Секреты совпадают, хотя никогда не передавались по сети
  final aliceSecretBytes = await aliceSharedSecret.extractBytes();
  final bobSecretBytes   = await bobSharedSecret.extractBytes();
  final secretsMatch     = _bytesEqual(aliceSecretBytes, bobSecretBytes);
  print('Секреты совпадают: $secretsMatch\n');

  print('=== Шифрование и расшифровка ===\n');

  const message = 'Привет, Боб! Это зашифрованное сообщение.';
  print('Исходное сообщение: $message\n');

  // Алиса шифрует
  final encrypted = await encryptMessage(aliceSharedSecret, message);
  final encoded   = encrypted.toBase64();
  print('Зашифровано (Base64): $encoded\n');

  // Боб расшифровывает
  final receivedEncrypted = EncryptedMessage.fromBase64(encoded);
  final decrypted = await decryptMessage(bobSharedSecret, receivedEncrypted);
  print('Расшифровано: $decrypted\n');

  print('Успех: ${message == decrypted}');
}

// ─────────────────────────────────────────────
//  Утилиты
// ─────────────────────────────────────────────

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}