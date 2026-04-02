class ImportError {
  final String id;
  final String nombre;

  ImportError({required this.id, required this.nombre});

  factory ImportError.fromJson(Map<String, dynamic> json) {
    return ImportError(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
    );
  }
}
