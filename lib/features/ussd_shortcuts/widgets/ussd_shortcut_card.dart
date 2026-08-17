import 'package:flutter/material.dart';
import '../../../models/operator.dart';
import '../models/ussd_shortcut.dart';

class UssdShortcutCard extends StatelessWidget {
  final UssdShortcut shortcut;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const UssdShortcutCard({
    super.key,
    required this.shortcut,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getOperatorColor() {
    switch (shortcut.operator) {
      case Operator.orange:
        return Colors.orange.withOpacity(0.15);
      case Operator.yas:
        return Colors.yellow.withOpacity(0.15);
    }
  }

  Color _getOperatorTextColor() {
    switch (shortcut.operator) {
      case Operator.orange:
        return Colors.orangeAccent;
      case Operator.yas:
        return Colors.yellowAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _getOperatorColor(),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        shortcut.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shortcut.operator.label,
                        style: TextStyle(
                          color: _getOperatorTextColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shortcut.code,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
