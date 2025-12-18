import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../models/organization.dart';

final adminServiceProvider = Provider((ref) => AdminService());

class AdminService {
  final _supabase = SupabaseConfig.client;

  Future<List<Organization>> getAllOrganizations() async {
    final response = await _supabase
        .from('organizations')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Organization.fromJson(json))
        .toList();
  }

  Future<void> extendTrial(String orgId, int days) async {
    final org = await _supabase
        .from('organizations')
        .select('trial_end_date')
        .eq('id', orgId)
        .single();

    final currentEndDate = org['trial_end_date'] != null
        ? DateTime.parse(org['trial_end_date'])
        : DateTime.now();

    final newEndDate = currentEndDate.add(Duration(days: days));

    await _supabase.from('organizations').update({
      'trial_end_date': newEndDate.toIso8601String(),
      'subscription_status': 'trial',
    }).eq('id', orgId);
  }

  Future<void> activateSubscription(
    String orgId,
    int durationDays,
    String plan,
  ) async {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationDays));

    await _supabase.from('organizations').update({
      'subscription_status': 'active',
      'subscription_plan': plan,
      'subscription_end_date': endDate.toIso8601String(),
    }).eq('id', orgId);
  }

  Future<void> extendSubscription(String orgId, int days) async {
    final org = await _supabase
        .from('organizations')
        .select('subscription_end_date')
        .eq('id', orgId)
        .single();

    final currentEndDate = org['subscription_end_date'] != null
        ? DateTime.parse(org['subscription_end_date'])
        : DateTime.now();

    final newEndDate = currentEndDate.add(Duration(days: days));

    await _supabase.from('organizations').update({
      'subscription_end_date': newEndDate.toIso8601String(),
      'subscription_status': 'active',
    }).eq('id', orgId);
  }

  Future<void> suspendOrganization(String orgId) async {
    await _supabase.from('organizations').update({
      'subscription_status': 'expired',
      'is_active': false,
    }).eq('id', orgId);
  }

  Future<void> reactivateOrganization(String orgId) async {
    // Get current subscription dates to determine correct status
  final org = await _supabase
      .from('organizations')
      .select('trial_end_date, subscription_end_date')
      .eq('id', orgId)
      .single();

  String newStatus;
  final now = DateTime.now();

  // Determine status based on dates
  if (org['subscription_end_date'] != null) {
    final subEnd = DateTime.parse(org['subscription_end_date']);
    newStatus = now.isBefore(subEnd) ? 'active' : 'expired';
  } else if (org['trial_end_date'] != null) {
    final trialEnd = DateTime.parse(org['trial_end_date']);
    newStatus = now.isBefore(trialEnd) ? 'trial' : 'expired';
  } else {
    newStatus = 'trial'; // Default
  }

    await _supabase.from('organizations').update({
      'subscription_status': newStatus,
      'is_active': true,
    }).eq('id', orgId);
  }

  Future<void> updateLimits(
    String orgId, {
    int? maxSites,
    int? maxExpenses,
    int? maxStorageMb,
  }) async {
    final updates = <String, dynamic>{};
    if (maxSites != null) updates['max_sites'] = maxSites;
    if (maxExpenses != null) updates['max_expenses'] = maxExpenses;
    if (maxStorageMb != null) updates['max_storage_mb'] = maxStorageMb;

    if (updates.isNotEmpty) {
      await _supabase.from('organizations').update(updates).eq('id', orgId);
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final orgs = await getAllOrganizations();

    return {
      'total_clients': orgs.length,
      'active_clients': orgs.where((o) => o.isActive && !o.isExpired).length,
      'trial_clients': orgs.where((o) => o.subscriptionStatus == 'trial').length,
      'expired_clients': orgs.where((o) => o.isExpired).length,
      'total_sites': orgs.fold<int>(0, (sum, o) => sum + o.totalSites),
      'total_expenses': orgs.fold<int>(0, (sum, o) => sum + o.totalExpenses),
    };
  }
}