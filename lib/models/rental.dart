enum RentalStatus {
  active,
  closedNormal,
  closedAutoUnverified,
  closedConfirmedAfterReview,
  missing;

  String get value => name;

  static RentalStatus fromString(String s) =>
      RentalStatus.values.firstWhere((e) => e.name == s);
}

class Rental {
  final int? id;
  final String itemTypeId;
  final int itemNumber;
  final int openedByGa;
  final int? closedByGa;
  final String? customerInitials;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? autoClosedAt;
  final RentalStatus status;
  final String date;
  final String location;

  const Rental({
    this.id,
    required this.itemTypeId,
    required this.itemNumber,
    required this.openedByGa,
    this.closedByGa,
    this.customerInitials,
    required this.startTime,
    this.endTime,
    this.autoClosedAt,
    required this.status,
    required this.date,
    required this.location,
  });

  static String formatInitials(String input) {
    final cleaned = input.replaceAll('.', '').trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(cleaned)) {
      throw ArgumentError('Initials must be 2 letters');
    }
    return '${cleaned[0]}.${cleaned[1]}';
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'item_type_id': itemTypeId,
    'item_number': itemNumber,
    'opened_by_ga': openedByGa,
    'closed_by_ga': closedByGa,
    'customer_initials': customerInitials,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'auto_closed_at': autoClosedAt?.toIso8601String(),
    'status': status.value,
    'date': date,
    'location': location,
  };

  factory Rental.fromMap(Map<String, dynamic> map) => Rental(
    id: map['id'] as int?,
    itemTypeId: map['item_type_id'] as String,
    itemNumber: map['item_number'] as int,
    openedByGa: map['opened_by_ga'] as int,
    closedByGa: map['closed_by_ga'] as int?,
    customerInitials: map['customer_initials'] as String?,
    startTime: DateTime.parse(map['start_time'] as String),
    endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
    autoClosedAt: map['auto_closed_at'] != null ? DateTime.parse(map['auto_closed_at'] as String) : null,
    status: RentalStatus.fromString(map['status'] as String),
    date: map['date'] as String,
    location: map['location'] as String,
  );

  Rental copyWith({
    int? id,
    String? itemTypeId,
    int? itemNumber,
    int? openedByGa,
    int? closedByGa,
    String? customerInitials,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? autoClosedAt,
    RentalStatus? status,
    String? date,
    String? location,
  }) {
    return Rental(
      id: id ?? this.id,
      itemTypeId: itemTypeId ?? this.itemTypeId,
      itemNumber: itemNumber ?? this.itemNumber,
      openedByGa: openedByGa ?? this.openedByGa,
      closedByGa: closedByGa ?? this.closedByGa,
      customerInitials: customerInitials ?? this.customerInitials,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      autoClosedAt: autoClosedAt ?? this.autoClosedAt,
      status: status ?? this.status,
      date: date ?? this.date,
      location: location ?? this.location,
    );
  }
}
