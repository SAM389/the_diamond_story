class Sale {
  final int? id;
  final int partyId;
  final int? diamondId;
  final double price;
  final String date;
  final String? notes;
  final String? createdAt;

  // Joined
  final String? partyName;
  final String? diamondCode;

  const Sale({
    this.id,
    required this.partyId,
    this.diamondId,
    required this.price,
    required this.date,
    this.notes,
    this.createdAt,
    this.partyName,
    this.diamondCode,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      diamondId: map['diamond_id'] as int?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      partyName: map['party_name'] as String?,
      diamondCode: map['diamond_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'party_id': partyId,
      if (diamondId != null) 'diamond_id': diamondId,
      'price': price,
      'date': date,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
