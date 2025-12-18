import 'package:flutter/material.dart';

class ActivateSubscriptionDialog extends StatefulWidget {
  const ActivateSubscriptionDialog({super.key});
  @override
  State<ActivateSubscriptionDialog> createState() =>
      _ActivateSubscriptionDialogState();
}

class _ActivateSubscriptionDialogState
    extends State<ActivateSubscriptionDialog> {
  int _days = 30;
  String _plan = 'basic';
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Activate Subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _plan,
            decoration: const InputDecoration(labelText: 'Plan'),
            items: const [
              DropdownMenuItem(value: 'basic', child: Text('Basic')),
              DropdownMenuItem(value: 'pro', child: Text('Pro')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _plan = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (days)',
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
              _buildQuickButton(30, '1 Month'),
              _buildQuickButton(90, '3 Months'),
              _buildQuickButton(180, '6 Months'),
              _buildQuickButton(365, '1 Year'),
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
          onPressed: () =>
              Navigator.pop(context, {'days': _days, 'plan': _plan}),
          child: const Text('Activate'),
        ),
      ],
    );
  }

  Widget _buildQuickButton(int days, String label) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () => setState(() => _days = days),
          child: Text('$days'),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
