class InventoryType {
  final String id;
  final String displayName;
  final int pricePence;
  final int totalCount;
  final bool isDefault;
  final bool isArchived;

  const InventoryType({
    required this.id,
    required this.displayName,
    required this.pricePence,
    required this.totalCount,
    required this.isDefault,
    this.isArchived = false,
  });

  static const List<InventoryType> defaults = [
    InventoryType(id: 'chair',     displayName: 'Deck Chair', pricePence: 500,  totalCount: 0, isDefault: true),
    InventoryType(id: 'sunbed',    displayName: 'Sunbed',     pricePence: 1050, totalCount: 0, isDefault: true),
    InventoryType(id: 'parasol',   displayName: 'Parasol',    pricePence: 950,  totalCount: 0, isDefault: true),
    InventoryType(id: 'windbreak', displayName: 'Windbreak',  pricePence: 950,  totalCount: 0, isDefault: true),
  ];

  String get priceDisplay {
    final pounds = pricePence ~/ 100;
    final pence = pricePence % 100;
    return '£$pounds.${pence.toString().padLeft(2, '0')}';
  }

  InventoryType copyWith({
    String? id,
    String? displayName,
    int? pricePence,
    int? totalCount,
    bool? isDefault,
    bool? isArchived,
  }) {
    return InventoryType(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      pricePence: pricePence ?? this.pricePence,
      totalCount: totalCount ?? this.totalCount,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'display_name': displayName,
    'price_pence': pricePence,
    'total_count': totalCount,
    'is_default': isDefault ? 1 : 0,
    'is_archived': isArchived ? 1 : 0,
  };

  factory InventoryType.fromMap(Map<String, dynamic> map) => InventoryType(
    id: map['id'] as String,
    displayName: map['display_name'] as String,
    pricePence: map['price_pence'] as int,
    totalCount: map['total_count'] as int,
    isDefault: (map['is_default'] as int) == 1,
    isArchived: (map['is_archived'] as int) == 1,
  );
}
