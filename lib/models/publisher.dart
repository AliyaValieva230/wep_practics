class Publisher {
  final int id;
  final String name;
  final String? address;
  final DateTime? deletedAt;

  const Publisher(
      {required this.id, required this.name, this.address, this.deletedAt});

  bool get isDeleted => deletedAt != null;

  Publisher copyWith(
      {int? id,
      String? name,
      String? address,
      DateTime? deletedAt,
      bool clearDeletedAt = false}) {
    return Publisher(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        address: json['address'] as String?,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
