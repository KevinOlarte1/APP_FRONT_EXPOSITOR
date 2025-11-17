import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeUserPage extends StatelessWidget {
  final String nombre;
  final String email;

  const HomeUserPage({super.key, required this.nombre, required this.email});

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
          "🙋 Bienvenido $nombre\n$email",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
    );
  }
}
