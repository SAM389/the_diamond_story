class Process {
  final int? id;
  final int diamondId;
  final int processTypeId;
  final double fee;
  final String partyName;
  final String fromDate;
  final String? toDate;
  final String status; // pending | completed
  final String? notes;
  final String? createdAt;

  // Joined fields (not stored in DB)
  final String? diamondCode;
  final String? processTypeName;
  final double? processTypeCost;

  const Process({
    this.id,
    required this.diamondId,
    required this.processTypeId,
    this.fee = 0,
    required this.partyName,
    required this.fromDate,
    this.toDate,
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.diamondCode,
    this.processTypeName,
    this.processTypeCost,
  });

  factory Process.fromMap(Map<String, dynamic> map) {
    return Process(
      id: map['id'] as int?,
      diamondId: map['diamond_id'] as int,
      processTypeId: map['process_type_id'] as int,
      fee: (map['fee'] as num?)?.toDouble() ?? 0,
      partyName: map['party_name'] as String? ?? '',
      fromDate: map['from_date'] as String? ?? '',
      toDate: map['to_date'] as String?,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      diamondCode: map['diamond_code'] as String?,
      processTypeName: map['process_type_name'] as String?,
      processTypeCost: (map['process_type_cost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'diamond_id': diamondId,
      'process_type_id': processTypeId,
      'fee': fee,
      'party_name': partyName,
      'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  Process copyWith({
    int? id,
    int? diamondId,
    int? processTypeId,
    double? fee,
    String? partyName,
    String? fromDate,
    String? toDate,
    String? status,
    String? notes,
    String? createdAt,
    String? diamondCode,
    String? processTypeName,
    double? processTypeCost,
  }) {
    return Process(
      id: id ?? this.id,
      diamondId: diamondId ?? this.diamondId,
      processTypeId: processTypeId ?? this.processTypeId,
      fee: fee ?? this.fee,
      partyName: partyName ?? this.partyName,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      diamondCode: diamondCode ?? this.diamondCode,
      processTypeName: processTypeName ?? this.processTypeName,
      processTypeCost: processTypeCost ?? this.processTypeCost,
    );
  }
}
