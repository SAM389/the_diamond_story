class Payment {
  final int? id;
  final int partyId;
  final double amount;
  final String type; // paid | received
  final String? category;
  final String date;
  final String status; // pending | completed
  final String? notes;

  // Joined
  final String? partyName;

  const Payment({
    this.id,
    required this.partyId,
    required this.amount,
    required this.type,
    this.category,
    required this.date,
    this.status = 'pending',
    this.notes,
    this.partyName,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'paid',
      category: map['category'] as String?,
      date: map['date'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      partyName: map['party_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'party_id': partyId,
      'amount': amount,
      'type': type,
      if (category != null) 'category': category,
      'date': date,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  Payment copyWith({
    int? id,
    int? partyId,
    double? amount,
    String? type,
    String? category,
    String? date,
    String? status,
    String? notes,
    String? partyName,
  }) {
    return Payment(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      partyName: partyName ?? this.partyName,
    );
  }
}
