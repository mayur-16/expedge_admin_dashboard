import 'package:expedge_admin_dashboard/widgets/add_organization_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/organization.dart';
import '../services/admin_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/extend_trial_dialog.dart';
import '../widgets/activate_subscription_dialog.dart';
import '../widgets/edit_limits_dialog.dart';
import '../widgets/reset_password_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<Organization> _organizations = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orgs = await ref.read(adminServiceProvider).getAllOrganizations();
      final stats = await ref.read(adminServiceProvider).getStatistics();

      if (mounted) {
        setState(() {
          _organizations = orgs;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<Organization> get _filteredOrganizations {
    var filtered = _organizations;

    // Apply status filter
    if (_filterStatus != 'all') {
      if (_filterStatus == 'active') {
        filtered = filtered.where((o) => o.isActive && !o.isExpired).toList();
      } else if (_filterStatus == 'trial') {
        filtered =
            filtered.where((o) => o.subscriptionStatus == 'trial').toList();
      } else if (_filterStatus == 'expired') {
        filtered = filtered.where((o) => o.isExpired).toList();
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exp Edge Admin Dashboard'),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => AddOrganizationDialog(),
              );
              _loadData(); // Refresh list
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Organization'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  if (_stats != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Total Clients',
                            value: _stats!['total_clients'].toString(),
                            icon: Icons.business,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Active Clients',
                            value: _stats!['active_clients'].toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Trial Clients',
                            value: _stats!['trial_clients'].toString(),
                            icon: Icons.timer,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Expired',
                            value: _stats!['expired_clients'].toString(),
                            icon: Icons.warning,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Filters and Search
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search clients...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Active')),
                          DropdownMenuItem(
                              value: 'trial', child: Text('Trial')),
                          DropdownMenuItem(
                              value: 'expired', child: Text('Expired')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filterStatus = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Clients Table
                  Text(
                    'Clients (${_filteredOrganizations.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 600,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 1200,
                      columns: const [
                        DataColumn2(
                            label: Text('Organization'), size: ColumnSize.L),
                        DataColumn2(label: Text('Email'), size: ColumnSize.L),
                        DataColumn2(label: Text('Status'), size: ColumnSize.S),
                        DataColumn2(label: Text('Plan'), size: ColumnSize.S),
                        DataColumn2(
                            label: Text('Days Left'), size: ColumnSize.S),
                        DataColumn2(label: Text('Sites'), size: ColumnSize.S),
                        DataColumn2(
                            label: Text('Expenses'), size: ColumnSize.S),
                        DataColumn2(label: Text('Storage'), size: ColumnSize.S),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.L),
                      ],
                      rows: _filteredOrganizations.map((org) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    org.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(org.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(org.email)),
                            DataCell(_buildStatusChip(org)),
                            DataCell(Text(org.subscriptionPlan.toUpperCase())),
                            DataCell(
                              Text(
                                '${org.daysLeft} days',
                                style: TextStyle(
                                  color: org.daysLeft < 3 ? Colors.red : null,
                                  fontWeight:
                                      org.daysLeft < 3 ? FontWeight.bold : null,
                                ),
                              ),
                            ),
                            DataCell(Text('${org.totalSites}/${org.maxSites}')),
                            DataCell(Text(
                                '${org.totalExpenses}/${org.maxExpenses}')),
                            DataCell(Text(
                                '${org.storageUsedMb.toStringAsFixed(1)} MB')),
                            DataCell(
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'extend_trial',
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer_outlined),
                                        SizedBox(width: 8),
                                        Text('Extend Trial'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'activate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline),
                                        SizedBox(width: 8),
                                        Text('Activate Subscription'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'extend_subscription',
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today),
                                        SizedBox(width: 8),
                                        Text('Extend Subscription'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit_limits',
                                    child: Row(
                                      children: [
                                        Icon(Icons.settings_outlined),
                                        SizedBox(width: 8),
                                        Text('Edit Limits'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reset_password',
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock_reset,
                                            color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Reset Password',
                                            style: TextStyle(
                                                color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                  if (org.isActive)
                                    const PopupMenuItem(
                                      value: 'suspend',
                                      child: Row(
                                        children: [
                                          Icon(Icons.block, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Suspend',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    )
                                  else
                                    const PopupMenuItem(
                                      value: 'reactivate',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check,
                                              color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Reactivate'),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) =>
                                    _handleAction(value, org),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusChip(Organization org) {
    Color color;
    String label;

    if (org.isExpired) {
      color = Colors.red;
      label = 'EXPIRED';
    } else if (org.subscriptionStatus == 'trial') {
      color = Colors.orange;
      label = 'TRIAL';
    } else if (org.subscriptionStatus == 'active') {
      color = Colors.green;
      label = 'ACTIVE';
    } else {
      color = Colors.grey;
      label = org.subscriptionStatus.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handleAction(dynamic action, Organization org) async {
    try {
      switch (action) {
        case 'extend_trial':
          final days = await showDialog<int>(
            context: context,
            builder: (_) => const ExtendTrialDialog(),
          );
          if (days != null) {
            await ref.read(adminServiceProvider).extendTrial(org.id, days);
            _loadData();
            _showSuccess('Trial extended by $days days');
          }
          break;

         case 'reset_password':
        final newPassword = await showDialog<String>(
          context: context,
          builder: (_) => ResetPasswordDialog(organization: org),
        );
        if (newPassword != null) {
          _showSuccess('Password reset successfully');
        }
        break;


        case 'activate':
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => const ActivateSubscriptionDialog(),
          );
          if (result != null) {
            await ref.read(adminServiceProvider).activateSubscription(
                  org.id,
                  result['days'],
                  result['plan'],
                );
            _loadData();
            _showSuccess('Subscription activated');
          }
          break;

        case 'extend_subscription':
          final days = await showDialog<int>(
            context: context,
            builder: (_) =>
                const ExtendTrialDialog(title: 'Extend Subscription'),
          );
          if (days != null) {
            await ref
                .read(adminServiceProvider)
                .extendSubscription(org.id, days);
            _loadData();
            _showSuccess('Subscription extended by $days days');
          }
          break;

        case 'edit_limits':
          final result = await showDialog<Map<String, int>>(
            context: context,
            builder: (_) => EditLimitsDialog(organization: org),
          );
          if (result != null) {
            await ref.read(adminServiceProvider).updateLimits(
                  org.id,
                  maxSites: result['maxSites'],
                  maxExpenses: result['maxExpenses'],
                  maxStorageMb: result['maxStorageMb'],
                );
            _loadData();
            _showSuccess('Limits updated');
          }
          break;

        case 'suspend':
          final confirm =
              await _showConfirmDialog('Suspend this organization?');
          if (confirm) {
            await ref.read(adminServiceProvider).suspendOrganization(org.id);
            _loadData();
            _showSuccess('Organization suspended');
          }
          break;

        case 'reactivate':
          await ref.read(adminServiceProvider).reactivateOrganization(org.id);
          _loadData();
          _showSuccess('Organization reactivated');
          break;
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }


  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
