class Organization {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String subscriptionStatus;
  final String subscriptionPlan;
  final DateTime? trialEndDate;
  final DateTime? subscriptionEndDate;
  final int storageUsed;
  final int totalSites;
  final int totalExpenses;
  final int maxSites;
  final int maxExpenses;
  final int maxStorageMb;
  final bool isActive;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.subscriptionStatus,
    required this.subscriptionPlan,
    this.trialEndDate,
    this.subscriptionEndDate,
    required this.storageUsed,
    required this.totalSites,
    required this.totalExpenses,
    required this.maxSites,
    required this.maxExpenses,
    required this.maxStorageMb,
    required this.isActive,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      subscriptionStatus: json['subscription_status'] ?? 'trial',
      subscriptionPlan: json['subscription_plan'] ?? 'basic',
      trialEndDate: json['trial_end_date'] != null 
          ? DateTime.parse(json['trial_end_date']) 
          : null,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'])
          : null,
      storageUsed: json['storage_used'] ?? 0,
      totalSites: json['total_sites'] ?? 0,
      totalExpenses: json['total_expenses'] ?? 0,
      maxSites: json['max_sites'] ?? 50,
      maxExpenses: json['max_expenses'] ?? 500,
      maxStorageMb: json['max_storage_mb'] ?? 100,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isExpired {
    final now = DateTime.now();
    if (subscriptionStatus == 'trial' && trialEndDate != null) {
      return now.isAfter(trialEndDate!);
    } else if (subscriptionStatus == 'active' && subscriptionEndDate != null) {
      return now.isAfter(subscriptionEndDate!);
    }
    return subscriptionStatus == 'expired';
  }

  int get daysLeft {
    final now = DateTime.now();
    DateTime? endDate;
    
    if (subscriptionStatus == 'trial' && trialEndDate != null) {
      endDate = trialEndDate;
    } else if (subscriptionStatus == 'active' && subscriptionEndDate != null) {
      endDate = subscriptionEndDate;
    }
    
    if (endDate == null) return 0;
    return endDate.difference(now).inDays;
  }

  double get storageUsedMb => storageUsed / (1024 * 1024);
}
