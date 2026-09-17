class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => [lastName, firstName, middleName]
      .where((s) => s != null && s.isNotEmpty)
      .join(' ');

  Author copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'country': country,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        middleName: json['middleName'] as String?,
        country: json['country'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
