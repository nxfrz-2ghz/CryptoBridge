// models/user.dart
import "dart:math";
import "dart:convert";
import "package:cryptography/cryptography.dart";

import "contact.dart";
import "../modules/disk_control.dart";
import "../modules/cryptography.dart";

class User {
  final String name;
  final String nodeID;
  final List<Contact> contacts;
  final CryptoKeys keyPair;

  // ─── Disk keys ────────────────────────────────────────────────────────────

  static const String _nodeIDKey      = "node_id";
  static const String _userListKey    = "userlist";
  static const String _userNameKey    = "user_name";
  static const String _privateKeyKey  = "private_key";
  static const String _publicKeyKey   = "public_key";
  static const String _contactsKey    = "contacts";

  // ─── Constructor ──────────────────────────────────────────────────────────

  const User({
    required this.name,
    required this.nodeID,
    required this.contacts,
    required this.keyPair,
  });

  static Future<User> create(String name) async {
    final nodeID   = _generateID();
    final keyPair  = await CryptoKeys.generate();
    final contacts = await _createTestContacts(nodeID);

    await _saveKeyPair(nodeID, keyPair);
    await _saveContacts(nodeID, contacts);
    await _saveUsername(nodeID, name);
    await _addToUserList(nodeID);

    return User(name: name, nodeID: nodeID, contacts: contacts, keyPair: keyPair);
  }

  static Future<User> load(String nodeID) async {
    final name     = await _loadUsername(nodeID);
    final keyPair  = await _loadKeyPair(nodeID);
    final contacts = await _loadContacts(nodeID);

    return User(name: name, nodeID: nodeID, contacts: contacts, keyPair: keyPair);
  }
  
  Future<void> save() async {
    _saveUsername(nodeID, name);
    _saveKeyPair(nodeID, keyPair);
    _saveContacts(nodeID, contacts);
  }

  // ─── Public ───────────────────────────────────────────────────────────────

  Future<User> addContact(Contact contact) async {
    final updated = [...contacts, contact];
    await _saveContacts(nodeID, updated);
    return User(name: name, nodeID: nodeID, contacts: updated, keyPair: keyPair);
  }

  Future<User> updateContact(Contact contact) async {
    final updated = contacts.map((c) =>
    c.nodeID == contact.nodeID ? contact : c
    ).toList();

    await _saveContacts(nodeID, updated);

    return User(
      name: name,
      nodeID: nodeID,
      contacts: updated,
      keyPair: keyPair,
    );
  }

  Future<User> removeContact(String contactID) async {
    final updated = contacts
        .where((c) => c.nodeID != contactID)
        .toList();

    await _saveContacts(nodeID, updated);

    return User(
      name: name,
      nodeID: nodeID,
      contacts: updated,
      keyPair: keyPair,
    );
  }


  // ─── Private ──────────────────────────────────────────────────────────────

  static String _key(String nodeID, String k) => "$nodeID:$k";

  static String _generateID() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll("=", "").substring(0, 16);
  }

  static Future<void> _addToUserList(String nodeID) async {
    List<String> list = [];
    if (await diskControl.has(_userListKey)) {
      list = (jsonDecode(await diskControl.get(_userListKey)) as List).cast<String>();
    }
    list.add(nodeID);
    await diskControl.set(_userListKey, jsonEncode(list));
  }

  // ─── Username ─────────────────────────────────────────────────────────────

  static Future<void> _saveUsername(String nodeID, String name) async {
    await diskControl.set(_key(nodeID, _userNameKey), name);
  }

  static Future<String> _loadUsername(String nodeID) async {
    return diskControl.get(_key(nodeID, _userNameKey));
  }

  // ─── CryptoKeys ───────────────────────────────────────────────────────────

  static Future<void> _saveKeyPair(String nodeID, CryptoKeys keyPair) async {
    final privateBytes = await keyPair.privateKey.extractPrivateKeyBytes();
    final publicBytes  = keyPair.exportPublicKey();

    await diskControl.set(_key(nodeID, _privateKeyKey), base64Encode(privateBytes));
    await diskControl.set(_key(nodeID, _publicKeyKey),  base64Encode(publicBytes));
  }

  static Future<CryptoKeys> _loadKeyPair(String nodeID) async {
    final privateB64 = await diskControl.get(_key(nodeID, _privateKeyKey));
    final publicB64  = await diskControl.get(_key(nodeID, _publicKeyKey));

    final privateBytes = base64Decode(privateB64);
    final publicBytes  = base64Decode(publicB64);

    final privateKey = await X25519().newKeyPairFromSeed(privateBytes);
    final publicKey  = SimplePublicKey(publicBytes, type: KeyPairType.x25519);

    return CryptoKeys(privateKey: privateKey, publicKey: publicKey);
  }

  // ─── Contacts ─────────────────────────────────────────────────────────────

  static Future<List<Contact>> _createTestContacts(String userNodeID) async {
    final random = Random();
    final contacts = <Contact>[];

    for (int i = 0; i < 5; i++) {
      final contactID = _generateID();
      contacts.add(Contact(
        name: "Test Contact ${random.nextInt(999999)}",
        nodeID: contactID,
        transportType: TransportType.test,
      ));
    }

    await _saveContacts(userNodeID, contacts);
    return contacts;
  }

  static Future<List<Contact>> _loadContacts(String nodeID) async {
    if (!await diskControl.has(_key(nodeID, _contactsKey))) return [];
    final jsonStr = await diskControl.get(_key(nodeID, _contactsKey));
    final list    = jsonDecode(jsonStr) as List;
    return list.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _saveContacts(String nodeID, List<Contact> contacts) async {
    final jsonStr = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await diskControl.set(_key(nodeID, _contactsKey), jsonStr);
  }
}
