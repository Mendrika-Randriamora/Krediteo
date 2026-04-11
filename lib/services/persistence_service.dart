import 'package:shared_preferences/shared_preferences.dart';
import '../models/operator.dart';

class PersistenceService {
  static const String _operatorKey = 'selected_operator';

  Future<void> saveOperator(Operator operator) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_operatorKey, operator.name);
  }

  Future<Operator> getOperator() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_operatorKey);
    if (name != null) {
      try {
        return Operator.values.byName(name);
      } catch (_) {
        return Operator.yas;
      }
    }
    return Operator.yas; // Default operator
  }
}
