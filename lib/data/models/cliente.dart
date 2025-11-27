class Cliente {
  final int id;
  final String cif;
  final String nombre;
  final int idVendedor;
  final List<int> idPedidos;

  Cliente({
    required this.id,
    required this.cif,
    required this.nombre,
    required this.idVendedor,
    required this.idPedidos,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json["id"],
      cif: json["cif"],
      nombre: json["nombre"],
      idVendedor: json["idVendedor"],
      idPedidos: List<int>.from(json["idPedidos"] ?? []),
    );
  }
}
