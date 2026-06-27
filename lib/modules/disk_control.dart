// modules/disk_control.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

final DiskControl diskControl = DiskControl.create();

abstract class DiskControl {
  factory DiskControl.create() {
    if (Platform.isWindows) {
      return WindowsDiskControl();
    } else {
      return AndroidDiskControl();
    }
  }

  Future<bool> has(String key);
  Future<String> get(String key);
  Future<void> set(String key, String value);
}

class WindowsDiskControl implements DiskControl {
  String? _windowsConfigPath;

  Future<String> _getWindowsPath() async {
    if (_windowsConfigPath != null) return _windowsConfigPath!;

    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);

    final saveDir = Directory(p.join(exeDir, 'storage'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    _windowsConfigPath = saveDir.path;
    return _windowsConfigPath!;
  }

  Future<File> _getFile(String key) async {
    final basePath = await _getWindowsPath();
    return File(p.join(basePath, '$key.txt'));
  }

  @override
  Future<bool> has(String key) async {
    final file = await _getFile(key);
    return file.exists();
  }

  @override
  Future<String> get(String key) async {
    final file = await _getFile(key);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return "";
  }

  @override
  Future<void> set(String key, String value) async {
    final file = await _getFile(key);
    await file.writeAsString(value);
  }
}

class AndroidDiskControl implements DiskControl {
  @override
  Future<bool> has(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  @override
  Future<String> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? "";
  }

  @override
  Future<void> set(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
