import '../enums/categoria_product.dart';

class Producto {
  int id;
  String descripcion;
  double precio;
  int categoriaId;
  String? categoria;

  Producto({
    required this.id,
    required this.descripcion,
    required this.precio,
    required this.categoriaId,
    this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      descripcion: json['descripcion'] ?? "Sin descripción",
      precio: (json['precio'] as num).toDouble(),
      categoriaId: json['idCategoria'],
      categoria: json['categoria'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'precio': precio,
      'idCategoria': categoriaId,
    };
  }
}
