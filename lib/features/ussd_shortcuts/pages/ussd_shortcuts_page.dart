import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../services/call_service.dart'; // Import CallService
import '../../../models/operator.dart'; // Import Operator
import '../models/ussd_shortcut.dart';
import '../services/ussd_service.dart';
import '../widgets/ussd_shortcut_card.dart';
import '../widgets/add_edit_ussd_dialog.dart';

class UssdShortcutsPage extends StatefulWidget {
  const UssdShortcutsPage({super.key});

  @override
  State<UssdShortcutsPage> createState() => _UssdShortcutsPageState();
}

class _UssdShortcutsPageState extends State<UssdShortcutsPage> {
  final _ussdService = UssdService();
  final _callService = CallService(); // Instantiate CallService
  List<UssdShortcut> _shortcuts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    await _ussdService.init();
    setState(() {
      _shortcuts = _ussdService.getAllShortcuts();
      _isLoading = false;
    });
  }

  Future<void> _launchUssd(String code, Operator operator) async {
    HapticFeedback.mediumImpact();
    final success = await _callService.call(code);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer la commande')),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditUssdDialog(
        onSave: (name, code, operator) async {
          final shortcut = UssdShortcut(
            id: const Uuid().v4(),
            name: name,
            code: code,
            operator: operator,
          );
          await _ussdService.addShortcut(shortcut);
          _loadShortcuts();
        },
      ),
    );
  }

  void _showEditDialog(UssdShortcut shortcut) {
    showDialog(
      context: context,
      builder: (context) => AddEditUssdDialog(
        shortcut: shortcut,
        onSave: (name, code, operator) async {
          final updated = shortcut.copyWith(
            name: name,
            code: code,
            operator: operator,
          );
          await _ussdService.updateShortcut(updated);
          _loadShortcuts();
        },
      ),
    );
  }

  Future<void> _deleteShortcut(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cette commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _ussdService.deleteShortcut(id);
      _loadShortcuts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Commandes rapides',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shortcuts.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _shortcuts.length,
                  itemBuilder: (context, index) {
                    final shortcut = _shortcuts[index];
                    return UssdShortcutCard(
                      shortcut: shortcut,
                      onTap: () => _launchUssd(shortcut.code, shortcut.operator),
                      onLongPress: () => _showOptions(shortcut),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF38BDF8),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showOptions(UssdShortcut shortcut) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.white),
            title: const Text('Modifier', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(shortcut);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _deleteShortcut(shortcut.id);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flash_off_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Aucune commande enregistrée',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
