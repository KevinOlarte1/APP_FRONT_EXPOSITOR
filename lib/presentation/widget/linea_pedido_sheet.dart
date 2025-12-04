import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LineasPedidoSheet extends StatelessWidget {
  final List<Map<String, dynamic>> lineas;

  const LineasPedidoSheet({super.key, required this.lineas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Líneas del Pedido",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Cabecera estilo tabla
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SizedBox(width: 40, child: Text("ID")),
              SizedBox(width: 120, child: Text("Nombre")),
              SizedBox(width: 60, child: Text("P. Unit")),
              SizedBox(width: 50, child: Text("Unid.")),
              SizedBox(width: 60, child: Text("Total")),
            ],
          ),

          const Divider(),

          // Filas dinámicas
          ...lineas.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 40, child: Text(e["id"].toString())),
                  SizedBox(width: 120, child: Text(e["nombre"])),
                  SizedBox(width: 60, child: Text(e["precio"].toString())),
                  SizedBox(width: 50, child: Text(e["cantidad"].toString())),
                  SizedBox(width: 60, child: Text(e["total"].toString())),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
