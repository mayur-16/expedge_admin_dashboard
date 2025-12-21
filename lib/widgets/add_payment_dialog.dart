import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/organization.dart';
import '../core/config/supabase_config.dart';

class AddPaymentDialog extends StatefulWidget {
  final Organization? organization; // Optional - can select any org

  const AddPaymentDialog({super.key, this.organization});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMethod = 'upi';
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  List<Organization> _allOrganizations = [];
  Organization? _selectedOrganization;

  @override
  void initState() {
    super.initState();
    _selectedOrganization = widget.organization;
    if (widget.organization == null) {
      _loadOrganizations();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    try {
      final supabase = SupabaseConfig.client;
      final response =
          await supabase.from('organizations').select('id, name , email, phone , created_at').order('name');

      final orgs = (response as List)
          .map((json) => Organization.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _allOrganizations = orgs;
          if (orgs.isNotEmpty) {
            _selectedOrganization = orgs[0];
          }
        });
      }
    } catch (e) {
      print('Error loading organizations: $e');
    }
  }

  Future<void> _addPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOrganization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an organization')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseConfig.client;

      await supabase.from('payment_history').insert({
        'organization_id': _selectedOrganization!.id,
        'amount': double.parse(_amountController.text),
        'currency': 'INR',
        'payment_method': _selectedMethod,
        'transaction_id': _transactionIdController.text.trim().isEmpty
            ? null
            : _transactionIdController.text.trim(),
        'payment_date': _paymentDate.toIso8601String().split('T')[0],
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'recorded_by': 'admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment Record'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organization Selector (if not pre-selected)
                if (widget.organization == null) ...[
                  DropdownButtonFormField<Organization>(
                    value: _selectedOrganization,
                    decoration: const InputDecoration(
                      labelText: 'Organization *',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _allOrganizations.map((org) {
                      return DropdownMenuItem(
                        value: org,
                        child: Text(org.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedOrganization = value);
                    },
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.organization!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: '5000',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _paymentDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(
                        value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedMethod = value);
                  },
                ),
                const SizedBox(height: 16),

                // Transaction ID
                TextFormField(
                  controller: _transactionIdController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction ID / Reference',
                    prefixIcon: Icon(Icons.tag),
                    hintText: 'UPI Ref / Cheque No / Receipt No',
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    hintText: 'e.g., Subscription renewal Q1 2024',
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Additional details...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Payment'),
        ),
      ],
    );
  }
}
