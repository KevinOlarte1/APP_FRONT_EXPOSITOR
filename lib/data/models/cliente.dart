class Cliente {
  final int id;
  final String cif;
  final String nombre;
  final String telefono;
  final String email;
  final int idVendedor;
  final List<int> idPedidos;
  final int pedidosCerrados;
  final int pedidosAbiertos;

  Cliente({
    required this.id,
    required this.cif,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.idVendedor,
    required this.idPedidos,
    required this.pedidosCerrados,
    required this.pedidosAbiertos,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      cif: json['cif'],
      nombre: json['nombre'],
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      idVendedor: json['idVendedor'],
      idPedidos: List<int>.from(json['idPedidos'] ?? []),
      pedidosCerrados: json['pedidosCerrados'] ?? 0,
      pedidosAbiertos: json['pedidosAbiertos'] ?? 0,
    );
  }
}
