import '../enums/categoria_product.dart';

class Producto {
  int id;
  String descripcion;
  double precio;
  CategoriaProducto categoria;

  Producto({
    required this.id,
    required this.descripcion,
    required this.precio,
    required this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      categoria: CategoriaProductoExt.fromString(json['categoria']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria.nameValue,
    };
  }
}
