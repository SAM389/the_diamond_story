class RoughStone {
  final int? id;
  final String lotNo;
  final String title;
  final double weight;
  final String quality;
  final double purchasePrice;
  final String purchaseDate;
  final int? supplierId;
  final String? notes;
  final String? createdAt;

  const RoughStone({
    this.id,
    required this.lotNo,
    required this.title,
    required this.weight,
    required this.quality,
    required this.purchasePrice,
    required this.purchaseDate,
    this.supplierId,
    this.notes,
    this.createdAt,
  });

  factory RoughStone.fromMap(Map<String, dynamic> map) {
    return RoughStone(
      id: map['id'] as int?,
      lotNo: map['lot_no'] as String,
      title: map['title'] as String? ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      quality: map['quality'] as String? ?? '',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchase_date'] as String? ?? '',
      supplierId: map['supplier_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lot_no': lotNo,
      'title': title,
      'weight': weight,
      'quality': quality,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate,
      if (supplierId != null) 'supplier_id': supplierId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  RoughStone copyWith({
    int? id,
    String? lotNo,
    String? title,
    double? weight,
    String? quality,
    double? purchasePrice,
    String? purchaseDate,
    int? supplierId,
    String? notes,
    String? createdAt,
  }) {
    return RoughStone(
      id: id ?? this.id,
      lotNo: lotNo ?? this.lotNo,
      title: title ?? this.title,
      weight: weight ?? this.weight,
      quality: quality ?? this.quality,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
