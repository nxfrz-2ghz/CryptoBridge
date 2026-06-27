// modules/cryptography.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

Translator translator = Translator();
class Translator {
  
  Future<Uint8List> encodeText(String text) async {
    Uint8List bytes = Uint8List.fromList(utf8.encode(text));
    return bytes;
  }
  
  Future<String> decodeText(Uint8List bytes) async {
    String text = utf8.decode(bytes);
    return text;
  }
  
}

class CryptoKeys {
  final SimpleKeyPair privateKey;
  final SimplePublicKey publicKey;

  const CryptoKeys({
    required this.privateKey,
    required this.publicKey,
  });

  static Future<CryptoKeys> generate() async {
    final pair = await X25519().newKeyPair();
    final pub  = await pair.extractPublicKey();
    return CryptoKeys(privateKey: pair, publicKey: pub);
  }

  Uint8List exportPublicKey() {
    return Uint8List.fromList(publicKey.bytes);
  }

}

class CryptoBridge {
  final CryptoKeys selfKeyPair;
  final SimplePublicKey theirPublicKey;

  // Constructors
  const CryptoBridge({
    required this.selfKeyPair,
    required this.theirPublicKey,
  });

  static CryptoBridge fromBytes({
    required CryptoKeys selfKeyPair,
    required Uint8List theirPublicKeyBytes,
  }) {
    return CryptoBridge(
      selfKeyPair: selfKeyPair,
      theirPublicKey: SimplePublicKey(
        theirPublicKeyBytes,
        type: KeyPairType.x25519,
      ),
    );
  }

  // Functions
  Future<SecretKey> _deriveSharedSecret() async {
    final raw = await X25519().sharedSecretKey(
      keyPair: selfKeyPair.privateKey,
      remotePublicKey: theirPublicKey,
    );
    return Hkdf(hmac: Hmac(Sha256()), outputLength: 32)
        .deriveKey(secretKey: raw);
  }

  Future<Uint8List> encrypt(Uint8List data) async {
    final algorithm = AesGcm.with256bits();
    final secret    = await _deriveSharedSecret();
    final nonce     = algorithm.newNonce();

    final box = await algorithm.encrypt(
      data,
      secretKey: secret,
      nonce: nonce,
    );

    // Формат: [12 байт nonce][16 байт mac][остальное ciphertext]
    return Uint8List.fromList([...nonce, ...box.mac.bytes, ...box.cipherText]);
  }

  Future<Uint8List> decrypt(Uint8List data) async {
    final algorithm = AesGcm.with256bits();
    final secret    = await _deriveSharedSecret();

    final box = SecretBox(
      data.sublist(28),
      nonce: data.sublist(0, 12),
      mac:   Mac(data.sublist(12, 28)),
    );

    return Uint8List.fromList(await algorithm.decrypt(box, secretKey: secret));
  }
}
