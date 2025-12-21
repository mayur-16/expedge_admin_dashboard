import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../core/config/supabase_config.dart';
import '../models/organization.dart';

class AddUserDialog extends StatefulWidget {
  final Organization organization;

  const AddUserDialog({super.key, required this.organization});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String _selectedRole = 'manager';
  bool _isLoading = false;
  String? _inviteLink;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseConfig.client;

      // Check if user already exists in this organization
      final existingUser = await supabase
          .from('users')
          .select('id')
          .eq('organization_id', widget.organization.id)
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('User with this email already exists in this organization');
      }

      // Check if there's an unused invite for this email
      final existingInvite = await supabase
          .from('invite_tokens')
          .select('token')
          .eq('organization_id', widget.organization.id)
          .eq('email', _emailController.text.trim())
          .eq('used', false)
          .maybeSingle();

      if (existingInvite != null) {
        throw Exception('An unused invite already exists for this email');
      }

      // Generate invite token
      final token = _generateToken();

      // Create invite record
      await supabase.from('invite_tokens').insert({
        'organization_id': widget.organization.id,
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
            content: Text('Invite created successfully!'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add User to ${widget.organization.name}'),
      content: SizedBox(
        width: 500,
        child: _inviteLink == null
            ? Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organization: ${widget.organization.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'User Email *',
                        hintText: 'user@company.com',
                        prefixIcon: Icon(Icons.email_outlined),
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
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'An invite link will be generated. Share it with the user.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'User Invite Created!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email: ${_emailController.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Role: ${_selectedRole.toUpperCase()}'),
                  const SizedBox(height: 16),
                  const Text('Share this invite link:'),
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
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _inviteLink!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Link expires in 7 days',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
            onPressed: _isLoading ? null : _createInvite,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate Invite'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }
}