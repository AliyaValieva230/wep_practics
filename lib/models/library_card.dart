class LibraryCard {
  final int id;
  final int readerId;
  final String barcode;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isActive;

  const LibraryCard({
    required this.id,
    required this.readerId,
    required this.barcode,
    required this.issuedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  LibraryCard copyWith(
      {int? id,
      int? readerId,
      String? barcode,
      DateTime? issuedAt,
      DateTime? expiresAt,
      bool? isActive}) {
    return LibraryCard(
      id: id ?? this.id,
      readerId: readerId ?? this.readerId,
      barcode: barcode ?? this.barcode,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'readerId': readerId,
        'barcode': barcode,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
      };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
        id: json['id'] as int? ?? 0,
        readerId: json['readerId'] as int? ?? 0,
        barcode: json['barcode'] as String? ?? '',
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );
}
