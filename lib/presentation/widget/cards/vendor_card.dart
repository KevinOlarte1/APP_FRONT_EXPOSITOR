import 'package:expositor_app/core/constants/app_colors.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class VendorCard extends StatelessWidget {
  final Vendedor vendedor;
  final Function() onTap;

  const VendorCard({super.key, required this.vendedor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------
    // Mapa temporal (hasta conectar con la API)
    // -----------------------------------------
    final Map<String, int> pedidos = {"abierto": 2, "cerrado": 3};

    final int abiertos = pedidos["abierto"] ?? 0;
    final int cerrados = pedidos["cerrado"] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 3),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------
            // Avatar + nombre + email
            // -----------------------------------------
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(vendedor.urlAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendedor.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vendedor.email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // -----------------------------------------
            // Donut (abierto vs cerrado)
            // -----------------------------------------
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue,
                          value: abiertos.toDouble(),
                          title: "",
                          radius: 30,
                        ),
                        PieChartSectionData(
                          color: const Color.fromARGB(255, 207, 206, 206),
                          value: cerrados.toDouble(),
                          title: "",
                          radius: 30,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // -----------------------------------------
                // Leyenda
                // -----------------------------------------
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
                        color: const Color.fromARGB(255, 207, 206, 206),
                        label: "CERRADOS",
                        value: cerrados,
                      ),
                    ],
                  ),
                ),
              ],
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
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value.toString(),
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
