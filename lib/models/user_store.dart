import "dart:convert";
import "package:flutter/cupertino.dart";

import "../modules/disk_control.dart";
import "contact.dart";
import "user.dart";

const key_cur_user = "current_user_id";

class UserStore extends ChangeNotifier {
  User? _user;
  List<User> _users = [];

  User? get user => _user;
  List<User> get users => _users;

  Future<void> load() async {
    await _loadUsers();
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _user = user;
    _users.add(user);
    await user.save();
    await diskControl.set(key_cur_user, user.nodeID);
    notifyListeners();
  }

  Future<void> changeUser(String nodeID) async {
    _user = _users.firstWhere(
          (u) => u.nodeID == nodeID,
      orElse: () => _users.first,
    );
    await diskControl.set(key_cur_user, nodeID);
    notifyListeners();
  }

  Future<void> removeUser(String nodeID) async {
    _users.removeWhere((u) => u.nodeID == nodeID);

    if (_users.isEmpty) {
      _user = null;
    } else if (_user?.nodeID == nodeID) {
      _user = _users.first;
    }

    notifyListeners();
  }

  Future<void> addContact(Contact contact) async {
    _user = await _user!.addContact(contact);
    notifyListeners();
  }

  Future<void> updateContact(Contact contact) async {
    _user = await _user!.updateContact(contact);
    notifyListeners();
  }

  Future<void> removeContact(String nodeID) async {
    _user = await _user!.removeContact(nodeID);
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    if (!await diskControl.has("userlist")) return;
    final jsonStr = await diskControl.get("userlist");
    final userList = (jsonDecode(jsonStr) as List).cast<String>();
    for (String userName in userList){
      _users.add(await User.load(userName));
    }

    if (await diskControl.has(key_cur_user)) {
      final nodeID = await diskControl.get(key_cur_user);
      _user = _users.firstWhere(
            (u) => u.nodeID == nodeID,
        orElse: () => _users.first,
      );
    }
    else {
      _user = users[0];
    }
  }
}