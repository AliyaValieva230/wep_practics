import 'library_card.dart';

class Reader {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final LibraryCard? card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => [lastName, firstName, middleName]
      .where((s) => s != null && s.isNotEmpty)
      .join(' ');

  Reader copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? email,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      email: email ?? this.email,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'email': email,
        'card': card?.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Reader.fromJson(Map<String, dynamic> json) => Reader(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        middleName: json['middleName'] as String?,
        email: json['email'] as String? ?? '',
        card: json['card'] != null
            ? LibraryCard.fromJson(json['card'] as Map<String, dynamic>)
            : null,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
