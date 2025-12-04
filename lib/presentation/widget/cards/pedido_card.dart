import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/pedido.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const PedidoCard({super.key, required this.pedido, required this.onTap});

  Color _estadoColor(bool cerrado) {
    return cerrado ? Colors.green : Colors.orange;
  }

  String _estadoTexto(bool cerrado) {
    return cerrado ? "Cerrado" : "Abierto";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -----------------------------
            ///   ID + ESTADO
            /// -----------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pedido #${pedido.id}",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _estadoColor(pedido.cerrado).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _estadoTexto(pedido.cerrado),
                    style: GoogleFonts.poppins(
                      color: _estadoColor(pedido.cerrado),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// -----------------------------
            ///   FECHA
            /// -----------------------------
            Text(
              "Fecha: ${formatFecha(pedido.fecha)}",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),

            const SizedBox(height: 6),

            /// -----------------------------
            ///   Nº LÍNEAS
            /// -----------------------------
            Text(
              "Líneas: ${pedido.idLineaPedido.length}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),

            const SizedBox(height: 6),

            /// -----------------------------
            ///   TOTAL (si existe)
            /// -----------------------------
            if (pedido.total != null)
              Text(
                "Total: ${pedido.total} €",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

            //const SizedBox(height: 12),

            /// -----------------------------
            ///   BOTÓN VER DETALLE
            /// -----------------------------
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Ver detalle →",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (_) {
      return fechaISO; // por si falla
    }
  }
}
