class IngresoCliente {
  final String clienteNombre;
  final int clienteId;
  final double total;

  IngresoCliente({
    required this.clienteNombre,
    required this.clienteId,
    required this.total,
  });

  factory IngresoCliente.fromJson(Map<String, dynamic> json) {
    return IngresoCliente(
      clienteNombre: json['clienteNombre'],
      clienteId: json['clienteId'],
      total: (json['total'] as num).toDouble(),
    );
  }
}
