class GA {
  final int gaNumber;
  final String displayName;

  const GA({required this.gaNumber, required this.displayName});

  Map<String, dynamic> toMap() => {
    'ga_number': gaNumber,
    'display_name': displayName,
  };

  factory GA.fromMap(Map<String, dynamic> map) => GA(
    gaNumber: map['ga_number'] as int,
    displayName: map['display_name'] as String,
  );
}
