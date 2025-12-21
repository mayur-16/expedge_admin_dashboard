// lib/models/payment.dart
class Payment {
  final String id;
  final String organizationId;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime paymentDate;
  final String? description;
  final String? notes;
  final String? recordedBy;
  final DateTime createdAt;

  // For display - organization name loaded separately
  String? organizationName;

  Payment({
    required this.id,
    required this.organizationId,
    required this.amount,
    this.currency = 'INR',
    this.paymentMethod,
    this.transactionId,
    required this.paymentDate,
    this.description,
    this.notes,
    this.recordedBy,
    required this.createdAt,
    this.organizationName,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      organizationId: json['organization_id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'INR',
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      description: json['description'],
      notes: json['notes'],
      recordedBy: json['recorded_by'],
      createdAt: DateTime.parse(json['created_at']),
      organizationName: json['organizations']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'description': description,
      'notes': notes,
      'recorded_by': recordedBy,
    };
  }
}