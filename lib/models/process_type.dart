class ProcessType {
  final int? id;
  final String name;
  final double cost;
  final String? createdAt;

  const ProcessType({this.id, required this.name, this.cost = 0, this.createdAt});

  factory ProcessType.fromMap(Map<String, dynamic> map) {
    return ProcessType(
      id: map['id'] as int?,
      name: map['name'] as String,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'cost': cost,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
