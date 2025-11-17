enum CategoriaProducto { PULSERA, COLLAR, ANILLO, CORDAJE }

extension CategoriaProductoExt on CategoriaProducto {
  String get nameValue {
    return toString().split('.').last;
  }

  static CategoriaProducto fromString(String value) {
    return CategoriaProducto.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => CategoriaProducto.COLLAR, // default si falla
    );
  }
}
