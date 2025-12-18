import 'package:flutter/material.dart';
import '../models/organization.dart';

class EditLimitsDialog extends StatefulWidget {
  final Organization organization;
  const EditLimitsDialog({super.key, required this.organization});
  @override
  State<EditLimitsDialog> createState() => _EditLimitsDialogState();
}

class _EditLimitsDialogState extends State<EditLimitsDialog> {
  late TextEditingController _sitesController;
  late TextEditingController _expensesController;
  late TextEditingController _storageController;
  @override
  void initState() {
    super.initState();
    _sitesController = TextEditingController(
      text: widget.organization.maxSites.toString(),
    );
    _expensesController = TextEditingController(
      text: widget.organization.maxExpenses.toString(),
    );
    _storageController = TextEditingController(
      text: widget.organization.maxStorageMb.toString(),
    );
  }

  @override
  void dispose() {
    _sitesController.dispose();
    _expensesController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Limits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sitesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Sites',
              suffixText: 'sites',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expensesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Expenses',
              suffixText: 'expenses',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _storageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Storage',
              suffixText: 'MB',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'maxSites': int.parse(_sitesController.text),
              'maxExpenses': int.parse(_expensesController.text),
              'maxStorageMb': int.parse(_storageController.text),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
