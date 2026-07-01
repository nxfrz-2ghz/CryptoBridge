// modules/cryptography.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

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

class KeyFingerprint {
  static Future<String> compute(Uint8List publicKey) async {
    final hash = await Sha256().hash(publicKey);
    return hash.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Future<String> short(Uint8List publicKey) async {
    final full = await compute(publicKey);
    // "a1b2c3...x7y8z9"
    return "${full.substring(0, 6)}...${full.substring(full.length - 6)}";
  }
}
