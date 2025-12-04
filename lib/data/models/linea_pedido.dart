class LineaPedido {
  final int id;
  final int idPedido;
  final int idProducto;
  final int cantidad;
  final double precio;

  LineaPedido({
    required this.id,
    required this.idPedido,
    required this.idProducto,
    required this.cantidad,
    required this.precio,
  });

  factory LineaPedido.fromJson(Map<String, dynamic> json) {
    return LineaPedido(
      id: json["id"],
      idPedido: json["idPedido"],
      idProducto: json["idProducto"],
      cantidad: json["cantidad"],
      precio: json["precio"].toDouble(),
    );
  }
}
