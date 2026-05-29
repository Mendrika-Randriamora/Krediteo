import 'package:flutter/material.dart';
import '../../../models/operator.dart';
import '../models/ussd_shortcut.dart';

class AddEditUssdDialog extends StatefulWidget {
  final UssdShortcut? shortcut;
  final Function(String name, String code, Operator operator) onSave;

  const AddEditUssdDialog({
    super.key,
    this.shortcut,
    required this.onSave,
  });

  @override
  State<AddEditUssdDialog> createState() => _AddEditUssdDialogState();
}

class _AddEditUssdDialogState extends State<AddEditUssdDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late Operator _selectedOperator;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shortcut?.name ?? '');
    _codeController = TextEditingController(text: widget.shortcut?.code ?? '');
    _selectedOperator = widget.shortcut?.operator ?? Operator.yas;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.shortcut == null ? 'Nouvelle commande' : 'Modifier la commande',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Nom de la commande', Icons.label_outline),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Code USSD (ex: #322*64#)', Icons.dialpad),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Code requis';
                  if (!RegExp(r'^[0-9#*]+$').hasMatch(value)) {
                    return 'Caractères invalides (#, *, chiffres uniquement)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Opérateur',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: Operator.values.map((op) {
                  final isSelected = _selectedOperator == op;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedOperator = op),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getOperatorBaseColor(op).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? _getOperatorBaseColor(op)
                              : Colors.white10,
                        ),
                      ),
                      child: Text(
                        op.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white38,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text,
                _codeController.text,
                _selectedOperator,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      filled: true,
      fillColor: Colors.black26,
    );
  }

  Color _getOperatorBaseColor(Operator op) {
    switch (op) {
      case Operator.orange:
        return Colors.orangeAccent;
      case Operator.yas:
        return Colors.yellowAccent;
    }
  }
}
