import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/models/stats/ingreso_cliente.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

class VendedorDetailPage extends StatefulWidget {
  final Vendedor vendedor;

  const VendedorDetailPage({super.key, required this.vendedor});

  @override
  State<VendedorDetailPage> createState() => _VendedorDetailPageState();
}

class _VendedorDetailPageState extends State<VendedorDetailPage> {
  final VendedorService vendedorService = VendedorService();

  late Future<Map<String, int>> futureCategorias;
  late Future<List<IngresoCliente>> futureGastosPorCliente;
  late Future<Map<String, int>> futurePedidos;

  @override
  void initState() {
    super.initState();

    futureCategorias = vendedorService.getStatsProductsByCategory(
      widget.vendedor.id,
    );

    // ← NUEVO MÉTODO CORRECTO
    futureGastosPorCliente = vendedorService.getIngresoAnualByCliente(
      widget.vendedor.id,
    );
    print("Vendedor: ${widget.vendedor.id}");

    futurePedidos = vendedorService.getNumPedidos(widget.vendedor.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        title: Text(
          widget.vendedor.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 30),

            //-----------------------------------------------------------
            // DONUT — Categorías
            //-----------------------------------------------------------
            Text(
              "Ventas por Categoría",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<Map<String, int>>(
              future: futureCategorias,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                final ventas = snapshot.data ?? {};
                return _buildDonut(ventas);
              },
            ),

            const SizedBox(height: 40),

            //-----------------------------------------------------------
            // DONUT — Pedidos
            //-----------------------------------------------------------
            Text(
              "Pedidos Abiertos / Cerrados",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<Map<String, int>>(
              future: futurePedidos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                final pedidos = snapshot.data ?? {};
                final int abiertos = pedidos["abierto"] ?? 0;
                final int cerrados = pedidos["cerrado"] ?? 0;

                return _buildPedidosDonut(abiertos, cerrados);
              },
            ),

            const SizedBox(height: 40),

            //-----------------------------------------------------------
            // BARRAS — Gastos por Cliente (NUEVO)
            //-----------------------------------------------------------
            Text(
              "Gastos por Cliente",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<IngresoCliente>>(
              future: futureGastosPorCliente,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                final ingresos = snapshot.data ?? [];
                if (ingresos.isEmpty) {
                  return Text(
                    "No hay datos de gastos por cliente.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  );
                }

                return _buildGastosPorClienteBarChart(ingresos);
              },
            ),

            const SizedBox(height: 40),
            _buildPlaceholder(),
          ],
        ),
      ),
    );
  }

  //----------------------------------------------------------------
  // HEADER
  //----------------------------------------------------------------
  Widget _buildHeader() {
    final vendedor = widget.vendedor;

    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: NetworkImage(vendedor.urlAvatar),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendedor.nombre,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(vendedor.email, style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  //----------------------------------------------------------------
  // DONUT — Categorías
  //----------------------------------------------------------------
  Widget _buildDonut(Map<String, int> ventas) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: ventas.entries.map((e) {
                return PieChartSectionData(
                  color: _colorForCategory(e.key),
                  value: e.value.toDouble(),
                  radius: 50,
                  title: "",
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ventas.entries.map((e) {
              return _LegendItem(
                color: _colorForCategory(e.key),
                label: e.key,
                value: e.value,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------
  // DONUT — Pedidos
  //----------------------------------------------------------------
  Widget _buildPedidosDonut(int abiertos, int cerrados) {
    return Row(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: abiertos.toDouble(),
                  radius: 50,
                  title: "",
                ),
                PieChartSectionData(
                  color: Colors.grey.shade300,
                  value: cerrados.toDouble(),
                  radius: 50,
                  title: "",
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: Colors.blue,
                label: "ABIERTOS",
                value: abiertos,
              ),
              const SizedBox(height: 12),
              _LegendItem(
                color: Colors.grey.shade300,
                label: "CERRADOS",
                value: cerrados,
              ),
            ],
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------
  // BARRAS — Gastos Por Cliente
  //----------------------------------------------------------------
  Widget _buildGastosPorClienteBarChart(List<IngresoCliente> ingresos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            maxY:
                ingresos.map((e) => e.total).reduce((a, b) => a > b ? a : b) *
                1.25,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 70,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < ingresos.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Transform.rotate(
                          angle: -0.6, // etiqueta diagonal estilo Material
                          child: Text(
                            ingresos[index].clienteNombre,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(10),
                getTooltipColor: (_) => Colors.grey.shade900,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final gasto = ingresos[groupIndex];

                  return BarTooltipItem(
                    "${gasto.clienteNombre}\n",
                    GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: "${rod.toY.toStringAsFixed(2)} €",
                        style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            barGroups: List.generate(
              ingresos.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: ingresos[i].total,
                    width: 32,
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(8),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY:
                          ingresos
                              .map((e) => e.total)
                              .reduce((a, b) => a > b ? a : b) *
                          1.25,
                      color: Colors.blue.shade100.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //----------------------------------------------------------------
  // COLORES — Categorías
  //----------------------------------------------------------------
  Color _colorForCategory(String category) {
    switch (category) {
      case "COLLAR":
        return Colors.blue;
      case "PULSERA":
        return Colors.pink;
      case "ANILLO":
        return Colors.orange;
      case "CORDAJE":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  //----------------------------------------------------------------
  // PLACEHOLDER
  //----------------------------------------------------------------
  Widget _buildPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Más estadísticas próximamente",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "Gráfico de ventas mensuales, ranking de productos, etc.",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          "$value",
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
