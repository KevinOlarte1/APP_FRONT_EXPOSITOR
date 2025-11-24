import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';

class HomeUserPage extends StatelessWidget {
  final Vendedor vendedorActual;

  const HomeUserPage({super.key, required this.vendedorActual});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Panel Usuario"),
        backgroundColor: const Color(0xFF3C75EF),
      ),
      body: Center(
        child: Text(
          "🙋 Bienvenido ${vendedorActual.nombre}\n${vendedorActual.email}",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
    );
  }
}
