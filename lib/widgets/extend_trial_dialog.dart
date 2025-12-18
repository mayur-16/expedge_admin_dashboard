import 'package:flutter/material.dart';

class ExtendTrialDialog extends StatefulWidget {
  final String title;
  const ExtendTrialDialog({
    super.key,
    this.title = 'Extend Trial',
  });
  @override
  State<ExtendTrialDialog> createState() => _ExtendTrialDialogState();
}

class _ExtendTrialDialogState extends State<ExtendTrialDialog> {
  int _days = 7;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Days',
              suffixText: 'days',
            ),
            onChanged: (value) {
              final days = int.tryParse(value);
              if (days != null && days > 0) {
                setState(() => _days = days);
              }
            },
            controller: TextEditingController(text: _days.toString()),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickButton(7),
              _buildQuickButton(14),
              _buildQuickButton(30),
              _buildQuickButton(90),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _days),
          child: const Text('Extend'),
        ),
      ],
    );
  }

  Widget _buildQuickButton(int days) {
    return OutlinedButton(
      onPressed: () => setState(() => _days = days),
      child: Text('$days'),
    );
  }
}
