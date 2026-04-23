import 'package:expositor_app/data/models/linea_pedido.dart';

class Pedido {
  final int id;
  final String fecha;
  final int idCliente;
  final List<int> idLineaPedido;
  final String comentario;

  final bool cerrado;
  int descuento;
  int iva;

  // Nuevos campos enviados por el backend (formato String)
  final String brutoTotal;
  final String baseImponible;
  final String precioIva;
  final String total;
  final String token;

  Pedido({
    required this.id,
    required this.fecha,
    required this.idCliente,
    required this.idLineaPedido,
    required this.cerrado,
    required this.descuento,
    required this.iva,
    required this.brutoTotal,
    required this.baseImponible,
    required this.precioIva,
    required this.total,
    required this.comentario,
    required this.token,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json["id"] ?? 0,
      fecha: json["fecha"] ?? "",
      idCliente: json["idCliente"] ?? 0,
      idLineaPedido: json["idLineaPedido"] != null
          ? List<int>.from(json["idLineaPedido"])
          : [],
      cerrado: json["cerrado"] ?? false,
      descuento: json["descuento"] ?? 0,
      iva: json["iva"] ?? 0,

      // Nuevos valores formateados por el backend (String)
      brutoTotal: json["brutoTotal"] ?? "0.00",
      baseImponible: json["baseImponible"] ?? "0.00",
      precioIva: json["precioIva"] ?? "0.00",
      total: json["total"] ?? "0.00",
      comentario: json["comentario"] ?? "",
      token: json["token"] ?? "",
    );
  }
}
