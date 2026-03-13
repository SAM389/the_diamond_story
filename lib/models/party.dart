class Party {
  final int? id;
  final String name;
  final String type; // supplier | customer | worker
  final String? phone;
  final String? address;
  final String? createdAt;

  const Party({
    this.id,
    required this.name,
    required this.type,
    this.phone,
    this.address,
    this.createdAt,
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'supplier',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  Party copyWith({
    int? id,
    String? name,
    String? type,
    String? phone,
    String? address,
    String? createdAt,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
