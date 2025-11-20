class Vendedor {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String role;
  String urlAvatar = "https://cdn.pfps.gg/pfps/2903-default-blue.png";

  Vendedor({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.role,
  });

  /// Crea un Vendedor desde un JSON de la API
  factory Vendedor.fromJson(Map<String, dynamic> json) {
    // En tu backend el role puede venir como "ADMIN" o como "[ADMIN]"
    final rawRole = (json['role'] ?? '').toString();
    final cleanedRole = rawRole.startsWith('[') && rawRole.endsWith(']')
        ? rawRole.substring(1, rawRole.length - 1)
        : rawRole;

    return Vendedor(
      id: (json['id'] ?? 0) is int
          ? json['id']
          : int.tryParse("${json['id']}") ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: cleanedRole,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'role': role,
  };
}
