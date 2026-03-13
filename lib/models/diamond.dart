class Diamond {
  final int? id;
  final String parentLot;
  final String diamondCode;
  final double weight;
  final String status; // raw | in_process | completed | sold
  final String? createdAt;

  const Diamond({
    this.id,
    required this.parentLot,
    required this.diamondCode,
    required this.weight,
    this.status = 'raw',
    this.createdAt,
  });

  factory Diamond.fromMap(Map<String, dynamic> map) {
    return Diamond(
      id: map['id'] as int?,
      parentLot: map['parent_lot'] as String? ?? '',
      diamondCode: map['diamond_code'] as String,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'raw',
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'parent_lot': parentLot,
      'diamond_code': diamondCode,
      'weight': weight,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  Diamond copyWith({
    int? id,
    String? parentLot,
    String? diamondCode,
    double? weight,
    String? status,
    String? createdAt,
  }) {
    return Diamond(
      id: id ?? this.id,
      parentLot: parentLot ?? this.parentLot,
      diamondCode: diamondCode ?? this.diamondCode,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
