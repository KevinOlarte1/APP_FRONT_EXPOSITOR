class LineaPedido {
  final int id;
  final int idPedido;
  final int idProducto;
  final int cantidad;
  final double precio;
  final int grupo; // <-- NUEVO CAMPO

  LineaPedido({
    required this.id,
    required this.idPedido,
    required this.idProducto,
    required this.cantidad,
    required this.precio,
    required this.grupo, // <-- AÑADIDO
  });

  factory LineaPedido.fromJson(Map<String, dynamic> json) {
    return LineaPedido(
      id: json["id"],
      idPedido: json["idPedido"],
      idProducto: json["idProducto"],
      cantidad: json["cantidad"],
      precio: json["precio"].toDouble(),
      grupo: json["grupo"] ?? 1, // <-- AÑADIDO (si viene null asigna 1)
    );
  }
}
