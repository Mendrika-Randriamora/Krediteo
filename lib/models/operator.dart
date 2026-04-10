enum Operator {
  yas('Yas', '#321*'),
  orange('Orange', '202');

  final String label;
  final String prefix;

  const Operator(this.label, this.prefix);

  String formatCall(String number) {
    switch (this) {
      case Operator.yas:
        return '$prefix$number#';
      case Operator.orange:
        return '$prefix$number';
    }
  }

  /// Encode le format pour URI tel:
  /// Pour Yas, # doit être %23
  String formatUri(String number) {
    final raw = formatCall(number);
    return raw.replaceAll('#', '%23');
  }
}
