import 'sale_item.dart';

class Sale {
  final int? id;
  final String? billNo;
  final String? deletedAt;
  final int partyId;
  final int? diamondId;
  final double price;
  final String date;
  final String? notes;
  final String? createdAt;

  // Joined
  final String? partyName;
  final String? diamondCode;
  final List<SaleItem>? _items;

  List<SaleItem> get items => _items ?? const [];

  const Sale({
    this.id,
    this.billNo,
    this.deletedAt,
    required this.partyId,
    this.diamondId,
    required this.price,
    required this.date,
    this.notes,
    this.createdAt,
    this.partyName,
    this.diamondCode,
    List<SaleItem>? items,
  }) : _items = items;

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      billNo: map['bill_no'] as String?,
      deletedAt: map['deleted_at'] as String?,
      partyId: map['party_id'] as int,
      diamondId: map['diamond_id'] as int?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      partyName: map['party_name'] as String?,
      diamondCode: map['diamond_code'] as String?,
      items: const [],
    );
  }

  Sale copyWith({
    int? id,
    String? billNo,
    String? deletedAt,
    int? partyId,
    int? diamondId,
    double? price,
    String? date,
    String? notes,
    String? createdAt,
    String? partyName,
    String? diamondCode,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      billNo: billNo ?? this.billNo,
      deletedAt: deletedAt ?? this.deletedAt,
      partyId: partyId ?? this.partyId,
      diamondId: diamondId ?? this.diamondId,
      price: price ?? this.price,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      partyName: partyName ?? this.partyName,
      diamondCode: diamondCode ?? this.diamondCode,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (billNo != null) 'bill_no': billNo,
      if (deletedAt != null) 'deleted_at': deletedAt,
      'party_id': partyId,
      if (diamondId != null) 'diamond_id': diamondId,
      'price': price,
      'date': date,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  bool get isDeleted => deletedAt != null && deletedAt!.trim().isNotEmpty;
}
