import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../core/config/supabase_config.dart';

class AddOrganizationDialog extends StatefulWidget {
  const AddOrganizationDialog({super.key});

  @override
  State<AddOrganizationDialog> createState() => _AddOrganizationDialogState();
}

class _AddOrganizationDialogState extends State<AddOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedPlan = 'basic';
  String _selectedRole = 'admin';
  int _trialDays = 14;
  bool _isLoading = false;
  String? _inviteLink;

  @override
  void dispose() {
    _orgNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }


Future<void> _createOrganization() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final supabase = SupabaseConfig.client;

    // Check if organization name already exists
    final existing = await supabase
        .from('organizations')
        .select('id')
        .ilike('name', _orgNameController.text.trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception('Organization "${_orgNameController.text.trim()}" already exists');
    }

    // Create organization
    final orgResponse = await supabase
        .from('organizations')
        .insert({
          'name': _orgNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'subscription_plan': _selectedPlan,
          'subscription_status': 'trial',
          'trial_end_date': DateTime.now()
              .add(Duration(days: _trialDays))
              .toIso8601String(),
        })
        .select()
        .single();

    final orgId = orgResponse['id'];

    // Generate invite token (client-side)
    final token = _generateToken();

    // Create invite record
    await supabase.from('invite_tokens').insert({
      'organization_id': orgId,
      'email': _emailController.text.trim(),
      'token': token,
      'role': _selectedRole,
      'expires_at': DateTime.now().add(Duration(days: 7)).toIso8601String(),
    });

    // Generate invite link
    final inviteLink = 'https://expedge.mangaloredrives.in/invite/$token';

    setState(() {
      _inviteLink = inviteLink;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
    print("Error creating organization: $e");
  }
}

// Add this helper method
String _generateToken() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  final random = Random.secure();
  return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Organization'),
      content: SizedBox(
        width: 500,
        child: _inviteLink == null
            ? Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _orgNameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization Name *',
                          hintText: 'ABC Construction',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter organization name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Admin Email *',
                          hintText: 'admin@company.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone (Optional)',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPlan,
                        decoration: const InputDecoration(labelText: 'Plan'),
                        items: const [
                          DropdownMenuItem(
                              value: 'basic', child: Text('Basic')),
                          DropdownMenuItem(value: 'pro', child: Text('Pro')),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _selectedPlan = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration:
                            const InputDecoration(labelText: 'Admin Role'),
                        items: const [
                          DropdownMenuItem(
                              value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                              value: 'manager', child: Text('Manager')),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _selectedRole = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _trialDays.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Trial Days',
                          suffixText: 'days',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final days = int.tryParse(value);
                          if (days != null) _trialDays = days;
                        },
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Organization Created!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Share this invite link with the admin:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inviteLink!,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _inviteLink!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The link expires in 7 days',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
      ),
      actions: [
        if (_inviteLink == null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _createOrganization,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create & Generate Invite'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }
}
