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

    futureGastosPorCliente = vendedorService.getIngresoAnualByCliente(
      widget.vendedor.id,
    );

    futurePedidos = vendedorService.getNumPedidos(widget.vendedor.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3C75EF),
        centerTitle: false,
        title: Text(
          widget.vendedor.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            // -------------------------------
            // TARJETA: Ventas por Categoría
            // -------------------------------
            _SectionCard(
              title: "Ventas por categoría",
              subtitle: "Distribución de productos vendidos",
              child: FutureBuilder<Map<String, int>>(
                future: futureCategorias,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorBox(message: "Error al cargar categorías");
                  }

                  final ventas = snapshot.data ?? {};
                  if (ventas.isEmpty) {
                    return _EmptyBox(message: "No hay ventas registradas.");
                  }

                  return _buildDonut(ventas);
                },
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------
            // TARJETA: Pedidos Abiertos/Cerrados
            // -------------------------------
            _SectionCard(
              title: "Pedidos abiertos / cerrados",
              subtitle: "Estado actual de los pedidos",
              child: FutureBuilder<Map<String, int>>(
                future: futurePedidos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorBox(message: "Error al cargar pedidos");
                  }

                  final pedidos = snapshot.data ?? {};
                  // Corrijo la clave a 'abiertos' por coherencia
                  final int abiertos =
                      pedidos["abiertos"] ?? pedidos["abierrtos"] ?? 0;
                  final int cerrados = pedidos["cerrados"] ?? 0;

                  if (abiertos == 0 && cerrados == 0) {
                    return _EmptyBox(message: "No hay pedidos registrados.");
                  }

                  return _buildPedidosDonut(abiertos, cerrados);
                },
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------
            // TARJETA: Gastos por Cliente
            // -------------------------------
            _SectionCard(
              title: "Gastos por cliente",
              subtitle: "Importe total facturado por cliente",
              child: FutureBuilder<List<IngresoCliente>>(
                future: futureGastosPorCliente,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorBox(
                      message: "Error al cargar gastos por cliente",
                    );
                  }

                  final ingresos = snapshot.data ?? [];
                  if (ingresos.isEmpty) {
                    return _EmptyBox(
                      message: "No hay datos de gastos por cliente.",
                    );
                  }

                  return _buildGastosPorClienteBarChart(ingresos);
                },
              ),
            ),

            const SizedBox(height: 24),

            _buildPlaceholder(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------
  Widget _buildHeader() {
    final vendedor = widget.vendedor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(vendedor.urlAvatar),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendedor.nombre,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vendedor.email,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DONUT — CATEGORÍAS
  // ------------------------------------------------------------------
  Widget _buildDonut(Map<String, int> ventas) {
    final total = ventas.values.fold<int>(0, (a, b) => a + b);

    return SizedBox(
      height: 190,
      child: Row(
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: ventas.entries.map((e) {
                  final porcentaje = total == 0
                      ? 0
                      : (e.value * 100 / total).round();

                  return PieChartSectionData(
                    color: _colorForCategory(e.key),
                    value: e.value.toDouble(),
                    radius: 56,
                    title: "$porcentaje%",
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ventas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = ventas.entries.elementAt(index);
                return _LegendItem(
                  color: _colorForCategory(entry.key),
                  label: entry.key,
                  value: entry.value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DONUT — PEDIDOS
  // ------------------------------------------------------------------
  Widget _buildPedidosDonut(int abiertos, int cerrados) {
    final total = abiertos + cerrados;
    final abiertosPct = total == 0 ? 0 : (abiertos * 100 / total).round();
    final cerradosPct = total == 0 ? 0 : (cerrados * 100 / total).round();

    return SizedBox(
      height: 190,
      child: Row(
        children: [
          SizedBox(
            height: 170,
            width: 170,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF3C75EF),
                    value: abiertos.toDouble(),
                    radius: 56,
                    title: "$abiertosPct%",
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.grey.shade300,
                    value: cerrados.toDouble(),
                    radius: 50,
                    title: "$cerradosPct%",
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: const Color(0xFF3C75EF),
                  label: "Abiertos",
                  value: abiertos,
                ),
                const SizedBox(height: 12),
                _LegendItem(
                  color: Colors.grey.shade300,
                  label: "Cerrados",
                  value: cerrados,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // BARRAS — GASTOS POR CLIENTE
  // ------------------------------------------------------------------
  Widget _buildGastosPorClienteBarChart(List<IngresoCliente> ingresos) {
    final screenWidth = MediaQuery.of(context).size.width;

    const double minBarWidth = 10;
    const double maxBarWidth = 34;
    const double barSpacing = 16;

    // Valor máximo para escalar el gráfico
    final double maxIngreso = ingresos
        .map((e) => e.total)
        .fold<double>(0, (max, v) => v > max ? v : max);

    // Anchura adaptativa de las barras según nº de clientes
    double adaptiveWidth =
        screenWidth / ingresos.length.clamp(4, 10); // 4–10 columnas visibles
    adaptiveWidth = adaptiveWidth.clamp(minBarWidth, maxBarWidth);

    final double chartWidth =
        ingresos.length * (adaptiveWidth + barSpacing) + 40;

    final double maxY = maxIngreso <= 0 ? 1 : maxIngreso * 1.15;
    final double interval = maxY <= 4
        ? 1
        : (maxY / 4); // 4 líneas horizontales aprox.

    return SizedBox(
      height: 320,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.start,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final ingreso = ingresos[group.x.toInt()];
                    return BarTooltipItem(
                      "${ingreso.clienteNombre}\n",
                      GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: "${rod.toY.toStringAsFixed(2)} €",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  top: BorderSide(color: Colors.transparent),
                  right: BorderSide(color: Colors.transparent),
                  left: BorderSide(color: Colors.transparent),
                  bottom: BorderSide(color: Colors.transparent),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 70,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= ingresos.length) {
                        return const SizedBox.shrink();
                      }
                      final nombre = ingresos[index].clienteNombre;
                      return Transform.rotate(
                        angle: -0.6, // vertical inclinado como querías
                        child: Text(
                          nombre,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(ingresos.length, (i) {
                final ingreso = ingresos[i];
                return BarChartGroupData(
                  x: i,
                  barsSpace: barSpacing,
                  barRods: [
                    BarChartRodData(
                      toY: ingreso.total.toDouble(),
                      width: adaptiveWidth,
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF3C75EF),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: const Color(0xFFE1E7FF),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // COLORES CATEGORÍAS
  // ------------------------------------------------------------------
  Color _colorForCategory(String category) {
    switch (category.toUpperCase()) {
      case "COLLAR":
        return const Color(0xFF3C75EF);
      case "PULSERA":
        return const Color(0xFFFF6FA2);
      case "ANILLO":
        return const Color(0xFFFFB347);
      case "CORDAJE":
        return const Color(0xFF4BD4A5);
      default:
        return Colors.grey.shade400;
    }
  }

  // ------------------------------------------------------------------
  // PLACEHOLDER
  // ------------------------------------------------------------------
  Widget _buildPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Más estadísticas próximamente",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Gráfico de ventas mensuales, ranking de productos, comparativa entre vendedores…",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
//    WIDGETS AUXILIARES
// ==================================================================

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
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          "$value",
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }
}
