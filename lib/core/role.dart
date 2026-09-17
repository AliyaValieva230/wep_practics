enum Role {
  reader(1, 'Читатель', '/my-loans'),
  librarian(2, 'Библиотекарь', '/librarian'),
  admin(3, 'Администратор', '/admin');

  final int level;
  final String label;
  final String homeRoute;

  const Role(this.level, this.label, this.homeRoute);

  static Role fromWire(String? v) {
    switch (v?.toUpperCase()) {
      case 'ADMIN':
      case 'ADMINISTRATOR':
        return Role.admin;
      case 'LIBRARIAN':
        return Role.librarian;
      default:
        return Role.reader;
    }
  }
}
