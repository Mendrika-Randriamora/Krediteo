import 'package:hive_flutter/hive_flutter.dart';
import '../models/ussd_shortcut.dart';

class UssdService {
  static const String _boxName = 'ussd_shortcuts';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  List<UssdShortcut> getAllShortcuts() {
    final box = Hive.box(_boxName);
    return box.values.map((e) => UssdShortcut.fromMap(e as Map)).toList();
  }

  Future<void> addShortcut(UssdShortcut shortcut) async {
    final box = Hive.box(_boxName);
    await box.put(shortcut.id, shortcut.toMap());
  }

  Future<void> updateShortcut(UssdShortcut shortcut) async {
    final box = Hive.box(_boxName);
    await box.put(shortcut.id, shortcut.toMap());
  }

  Future<void> deleteShortcut(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }
}
