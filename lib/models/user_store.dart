import "dart:convert";
import "package:flutter/cupertino.dart";

import "../modules/disk_control.dart";
import "contact.dart";
import "user.dart";

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

  Future<void> _loadUsers() async {
    if (!await diskControl.has("userlist")) return;
    final jsonStr = await diskControl.get("userlist");
    final userList = (jsonDecode(jsonStr) as List).cast<String>();
    for (String userName in userList){
      _users.add(await User.load(userName));
    }
    _user = users[0];
  }
}