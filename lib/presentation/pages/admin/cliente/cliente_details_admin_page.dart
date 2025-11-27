import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

class ClienteDetailsAdminPage extends StatefulWidget {
  final Cliente cliente;

  const ClienteDetailsAdminPage({super.key, required this.cliente});

  @override
  State<ClienteDetailsAdminPage> createState() =>
      _ClienteDetailsAdminPageState();
}

class _ClienteDetailsAdminPageState extends State<ClienteDetailsAdminPage> {
  final VendedorService vendedorService = VendedorService();
  final ClienteService clienteService = ClienteService();

  late Future<Vendedor?> futureVendedor;

  @override
  void initState() {
    super.initState();
    futureVendedor = vendedorService.getById(widget.cliente.idVendedor);
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.cliente;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        title: Text(
          "Cliente: ${cliente.nombre}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -----------------------------------------------------------
            // FOTO CIRCULAR
            // -----------------------------------------------------------
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue.shade200,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cliente.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cliente.cif,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // -----------------------------------------------------------
            // CARD 1 — INFO CLIENTE
            // -----------------------------------------------------------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Información del Cliente",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _infoRow("ID Cliente", cliente.id.toString()),
                    _infoRow("Nombre", cliente.nombre),
                    _infoRow("CIF", cliente.cif),

                    const SizedBox(height: 10),

                    // FUTURE BUILDER → vendedor asociado
                    FutureBuilder<Vendedor?>(
                      future: futureVendedor,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _infoRow("Vendedor asociado", "Cargando...");
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          return _infoRow("Vendedor asociado", "No disponible");
                        }

                        final v = snapshot.data!;
                        return _infoRow(
                          "Vendedor asociado",
                          "${v.nombre} ${v.apellido} — ${v.email}",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------
            // CARD 2 — INGRESOS ANUALES (GRÁFICA)
            // -----------------------------------------------------------
            FutureBuilder<Map<String, double>>(
              future: clienteService.getIngresoAnual(widget.cliente.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No hay datos de ingresos anuales.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                final years = data.keys.toList();
                final values = data.values.toList();
                final maxValue = values.reduce((a, b) => a > b ? a : b);

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Estadísticas — Ingreso Anual",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 260,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width:
                                  (data.length * 120).toDouble() <
                                      MediaQuery.of(context).size.width
                                  ? MediaQuery.of(context).size.width
                                  : (data.length * 120).toDouble(),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.start,
                                  minY: 0,
                                  maxY: maxValue * 1.25,

                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipRoundedRadius: 8,
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                            return BarTooltipItem(
                                              "${years[group.x.toInt()]}\n",
                                              const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      "${rod.toY.toStringAsFixed(2)} €",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                    ),
                                  ),

                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: (maxValue / 5)
                                        .roundToDouble(),
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.shade300,
                                      strokeWidth: 1,
                                    ),
                                  ),

                                  borderData: FlBorderData(show: false),

                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(),
                                    rightTitles: const AxisTitles(),
                                    leftTitles: const AxisTitles(),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 ||
                                              index >= years.length) {
                                            return const SizedBox.shrink();
                                          }

                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              years[index],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  barGroups: List.generate(
                                    data.length,
                                    (i) => BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: values[i],
                                          width: 35,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          color: const Color(0xFF3C75EF),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------
            // CARD 3 — PEDIDOS
            // -----------------------------------------------------------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pedidos del Cliente",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _infoRow(
                      "Número total",
                      cliente.idPedidos.length.toString(),
                    ),

                    const SizedBox(height: 10),

                    if (cliente.idPedidos.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: cliente.idPedidos
                            .map(
                              (id) => Chip(
                                label: Text("Pedido $id"),
                                backgroundColor: Colors.blue.shade50,
                              ),
                            )
                            .toList(),
                      )
                    else
                      const Text(
                        "Este cliente no tiene pedidos.",
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGET FILA DE INFO
  // -----------------------------------------------------------
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
