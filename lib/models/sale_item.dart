class SaleItem {
  final int? id;
  final int saleId;
  final int diamondId;
  final double amount;
  final String? createdAt;

  // Joined for UI
  final String? diamondCode;
  final double? diamondWeight;

  const SaleItem({
    this.id,
    required this.saleId,
    required this.diamondId,
    required this.amount,
    this.createdAt,
    this.diamondCode,
    this.diamondWeight,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      diamondId: map['diamond_id'] as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] as String?,
      diamondCode: map['diamond_code'] as String?,
      diamondWeight: (map['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'diamond_id': diamondId,
      'amount': amount,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
