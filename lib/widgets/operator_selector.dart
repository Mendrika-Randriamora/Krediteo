import 'package:flutter/material.dart';
import '../models/operator.dart';
import '../features/ussd_shortcuts/pages/ussd_shortcuts_page.dart';

class OperatorSelector extends StatelessWidget {
  final Operator selectedOperator;
  final ValueChanged<Operator> onOperatorChanged;
  final bool isFlashOn;

  const OperatorSelector({
    super.key,
    required this.selectedOperator,
    required this.onOperatorChanged,
    this.isFlashOn = false,
  });

  void _openShortcuts(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UssdShortcutsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isFlashOn ? Colors.white.withOpacity(0.4) : Colors.white10,
            ),
            boxShadow: isFlashOn
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: Operator.values.map((operator) {
              final isSelected = operator == selectedOperator;
              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    onOperatorChanged(operator);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF38BDF8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    operator.label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white60,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _openShortcuts(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isFlashOn ? Colors.white.withOpacity(0.4) : Colors.white10,
              ),
              boxShadow: isFlashOn
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
