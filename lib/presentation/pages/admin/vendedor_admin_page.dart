import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expositor_app/data/models/vendedor.dart';

class VendedorDetailPage extends StatelessWidget {
  final Vendedor vendedor;

  const VendedorDetailPage({super.key, required this.vendedor});

  @override
  Widget build(BuildContext context) {
    final ventasPorCategoria = vendedor.ventasPorCategoria;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        title: Text(
          vendedor.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------
            //       INFO DEL VENDEDOR
            // ----------------------------------
            Row(
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
                    Text(
                      vendedor.email,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              "Ventas por Categoría",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------
            //        ROSCO + LEYENDA
            // ----------------------------------
            Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue,
                          value: ventasPorCategoria['COLLAR']?.toDouble() ?? 0,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: Colors.pink,
                          value: ventasPorCategoria['PULSERA']?.toDouble() ?? 0,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: ventasPorCategoria['ANILLO']?.toDouble() ?? 0,
                          radius: 50,
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
                        label: "COLLAR",
                        value: ventasPorCategoria["COLLAR"] ?? 0,
                      ),
                      const SizedBox(height: 10),
                      _LegendItem(
                        color: Colors.pink,
                        label: "PULSERA",
                        value: ventasPorCategoria["PULSERA"] ?? 0,
                      ),
                      const SizedBox(height: 10),
                      _LegendItem(
                        color: Colors.orange,
                        label: "ANILLO",
                        value: ventasPorCategoria["ANILLO"] ?? 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ----------------------------------
            //   ESPACIO PARA GRÁFICAS FUTURAS
            // ----------------------------------
            Text(
              "Más estadísticas próximamente",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
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
        ),
      ),
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
