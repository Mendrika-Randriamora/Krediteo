import '../../../models/operator.dart';

class UssdShortcut {
  final String id;
  final String name;
  final String code;
  final Operator operator;

  UssdShortcut({
    required this.id,
    required this.name,
    required this.code,
    required this.operator,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'operator': operator.index,
    };
  }

  factory UssdShortcut.fromMap(Map<dynamic, dynamic> map) {
    return UssdShortcut(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      operator: Operator.values[map['operator'] as int],
    );
  }

  UssdShortcut copyWith({
    String? name,
    String? code,
    Operator? operator,
  }) {
    return UssdShortcut(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      operator: operator ?? this.operator,
    );
  }
}
