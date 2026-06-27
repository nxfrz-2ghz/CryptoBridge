import "dart:convert";
import "package:flutter/cupertino.dart";

import "../modules/disk_control.dart";
import "contact.dart";
import "user.dart";

class UserStore extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  Future<void> load() async {
    _user = await _loadUser();
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _user = user;
    await user.save();
    notifyListeners();
  }

  Future<void> updateContact(Contact contact) async {
    _user = await _user!.updateContact(contact);
    notifyListeners();
  }

  Future<User?> _loadUser() async {
    const key = "userlist";
    if (!await diskControl.has(key)) return null;

    final jsonStr  = await diskControl.get(key);
    final userList = (jsonDecode(jsonStr) as List).cast<String>();
    if (userList.isEmpty) return null;

    return User.load(userList[0]);
  }
}