import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/cliente.dart';

class CardCliente extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback? onTap;

  const CardCliente({super.key, required this.cliente, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 350,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FOTO REDONDA
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 3),
              ),
              child: const Icon(Icons.person, size: 55, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // NOMBRE
            Text(
              cliente.nombre,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            // CIF
            Text(
              "CIF: ${cliente.cif}",
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 6),

            // NÚMERO DE PEDIDOS
            Text(
              "Pedidos: ${cliente.idPedidos.length}",
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
