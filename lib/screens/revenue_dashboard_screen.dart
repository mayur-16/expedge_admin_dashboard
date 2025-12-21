import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/payment.dart';
import '../core/config/supabase_config.dart';
import '../widgets/add_payment_dialog.dart';

class RevenueDashboardScreen extends StatefulWidget {
  const RevenueDashboardScreen({super.key});

  @override
  State<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends State<RevenueDashboardScreen> {
  List<Payment> _payments = [];
  List<Map<String, dynamic>> _orgRevenue = [];
  bool _isLoading = true;
  String _viewMode = 'all'; // 'all' or 'by_org'
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  // Stats
  double _totalRevenue = 0;
  int _totalTransactions = 0;
  double _avgTransaction = 0;
  int _uniqueClients = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseConfig.client;

      // Build query with optional date filters
      dynamic query = supabase
          .from('payment_history')
          .select('*, organizations(name)');

      if (_filterStartDate != null) {
        query = query.gte('payment_date', _filterStartDate!.toIso8601String());
      }
      if (_filterEndDate != null) {
        query = query.lte('payment_date', _filterEndDate!.toIso8601String());
      }

      query = query.order('payment_date', ascending: false);

      final response = await query;

      final payments =
          (response as List).map((json) => Payment.fromJson(json)).toList();

      // Calculate stats
      final total = payments.fold<double>(0, (sum, p) => sum + p.amount);
      final count = payments.length;
      final avg = count > 0 ? total / count : 0;
      final uniqueOrgs = payments.map((p) => p.organizationId).toSet().length;

      // Calculate organization-wise revenue
      final orgMap = <String, Map<String, dynamic>>{};
      for (var payment in payments) {
        final orgId = payment.organizationId;
        if (!orgMap.containsKey(orgId)) {
          orgMap[orgId] = {
            'name': payment.organizationName ?? 'Unknown',
            'total': 0.0,
            'count': 0,
            'lastPayment': payment.paymentDate,
          };
        }
        orgMap[orgId]!['total'] += payment.amount;
        orgMap[orgId]!['count'] += 1;

        // Update last payment if newer
        if (payment.paymentDate.isAfter(orgMap[orgId]!['lastPayment'])) {
          orgMap[orgId]!['lastPayment'] = payment.paymentDate;
        }
      }

      final orgRevenue = orgMap.values.toList()
        ..sort(
            (a, b) => (b['total'] as double).compareTo(a['total'] as double));

      if (mounted) {
        setState(() {
          _payments = payments;
          _orgRevenue = orgRevenue;
          _totalRevenue = total;
          _totalTransactions = count;
          _avgTransaction = avg.toDouble();
          _uniqueClients = uniqueOrgs;
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

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _filterStartDate = range.start;
        _filterEndDate = range.end;
      });
      _loadData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Dashboard'),
        actions: [
          // Date Filter
          if (_filterStartDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text(
                  '${dateFormat.format(_filterStartDate!)} - ${dateFormat.format(_filterEndDate!)}',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: _clearDateFilter,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) => const AddPaymentDialog(),
              );
              if (result == true) _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Payment'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Revenue',
                          currencyFormat.format(_totalRevenue),
                          Icons.account_balance_wallet,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Transactions',
                          _totalTransactions.toString(),
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Avg Transaction',
                          currencyFormat.format(_avgTransaction),
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Paying Clients',
                          _uniqueClients.toString(),
                          Icons.business,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // View Mode Toggle
                  Row(
                    children: [
                      Text(
                        'View Mode:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'all',
                            label: Text('All Payments'),
                            icon: Icon(Icons.list),
                          ),
                          ButtonSegment(
                            value: 'by_org',
                            label: Text('By Organization'),
                            icon: Icon(Icons.business),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() => _viewMode = selection.first);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content based on view mode
                  if (_viewMode == 'all')
                    _buildAllPaymentsView()
                  else
                    _buildOrganizationView(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPaymentsView() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      height: 600,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        columns: const [
          DataColumn2(label: Text('Date'), size: ColumnSize.S),
          DataColumn2(label: Text('Organization'), size: ColumnSize.L),
          DataColumn2(label: Text('Amount'), size: ColumnSize.S),
          DataColumn2(label: Text('Method'), size: ColumnSize.S),
          DataColumn2(label: Text('Transaction ID'), size: ColumnSize.M),
          DataColumn2(label: Text('Description'), size: ColumnSize.L),
        ],
        rows: _payments.map((payment) {
          return DataRow(
            cells: [
              DataCell(Text(dateFormat.format(payment.paymentDate))),
              DataCell(Text(payment.organizationName ?? 'Unknown')),
              DataCell(
                Text(
                  currencyFormat.format(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(payment.paymentMethod?.toUpperCase() ?? 'N/A')),
              DataCell(Text(payment.transactionId ?? '-')),
              DataCell(Text(payment.description ?? '-')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrganizationView() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      height: 600,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        columns: const [
          DataColumn2(label: Text('Organization'), size: ColumnSize.L),
          DataColumn2(label: Text('Total Revenue'), size: ColumnSize.M),
          DataColumn2(label: Text('Transactions'), size: ColumnSize.S),
          DataColumn2(label: Text('Avg Payment'), size: ColumnSize.M),
          DataColumn2(label: Text('Last Payment'), size: ColumnSize.M),
        ],
        rows: _orgRevenue.map((org) {
          final total = org['total'] as double;
          final count = org['count'] as int;
          final avg = total / count;
          final lastPayment = org['lastPayment'] as DateTime;

          return DataRow(
            cells: [
              DataCell(Text(
                org['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              )),
              DataCell(Text('$count')),
              DataCell(Text(currencyFormat.format(avg))),
              DataCell(Text(dateFormat.format(lastPayment))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
