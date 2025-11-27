import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

class ConfigVendedorDetailPage extends StatefulWidget {
  final Vendedor vendedor;

  const ConfigVendedorDetailPage({super.key, required this.vendedor});

  @override
  State<ConfigVendedorDetailPage> createState() =>
      _ConfigVendedorDetailPageState();
}

class _ConfigVendedorDetailPageState extends State<ConfigVendedorDetailPage> {
  final VendedorService vendedorService = VendedorService();

  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController emailCtrl;
  final TextEditingController passwordCtrl = TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    // Inicializamos los inputs con los valores actuales
    nombreCtrl = TextEditingController(text: widget.vendedor.nombre);
    apellidoCtrl = TextEditingController(text: widget.vendedor.apellido);
    emailCtrl = TextEditingController(text: widget.vendedor.email);
  }

  // --------------------------------------------------------------------
  //   INPUT GENÉRICO (Igual al usado en ConfigVendedorPage original)
  // --------------------------------------------------------------------
  Widget _input({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --------------------------------------------------------------------
  //           GUARDAR CAMBIOS
  // --------------------------------------------------------------------
  Future<void> _save() async {
    setState(() => isSaving = true);

    final updated = Vendedor(
      id: widget.vendedor.id,
      nombre: nombreCtrl.text,
      apellido: apellidoCtrl.text,
      email: emailCtrl.text,
      role: widget.vendedor.role,
    );

    final success = await vendedorService.updateVendedor(
      updated,
      password: passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
    );

    setState(() => isSaving = false);

    if (success) {
      Navigator.pop(context, updated); // ← DEVUELVE EL VENDEDOR NUEVO
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al actualizar", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------------------------
  //                             UI PRINCIPAL
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),

      // -------------------------------------------------------
      // APP BAR PERSONALIZADO
      // -------------------------------------------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3C75EF),
        centerTitle: false,
        title: Text(
          "${widget.vendedor.nombre} ${widget.vendedor.apellido}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            // -------------------------------------------------------
            // CARD — DATOS DEL VENDEDOR (Reutilizado)
            // -------------------------------------------------------
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
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
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(widget.vendedor.urlAvatar),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _input(label: "Nombre", controller: nombreCtrl),
                  _input(label: "Apellido", controller: apellidoCtrl),
                  _input(label: "Correo", controller: emailCtrl),
                  _input(
                    label: "Nueva contraseña",
                    controller: passwordCtrl,
                    obscure: true,
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C75EF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Guardar cambios",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
