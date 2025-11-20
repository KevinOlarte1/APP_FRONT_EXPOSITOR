class CategoriaCount {
  final String categoria;
  final int total;

  CategoriaCount({required this.categoria, required this.total});

  factory CategoriaCount.fromJson(Map<String, dynamic> json) {
    return CategoriaCount(categoria: json["categoria"], total: json["total"]);
  }
}
