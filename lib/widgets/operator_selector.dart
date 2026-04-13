import 'package:flutter/material.dart';
import '../models/operator.dart';

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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
