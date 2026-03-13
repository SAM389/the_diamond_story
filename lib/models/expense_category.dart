class ExpenseCategory {
  final int? id;
  final String name;
  final String? createdAt;

  const ExpenseCategory({this.id, required this.name, this.createdAt});

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
