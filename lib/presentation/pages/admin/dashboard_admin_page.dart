import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/presentation/widget/cards/vendor_card.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/presentation/pages/admin/vendedor_admin_page.dart';

class VendedoresDashboardPage extends StatelessWidget {
  VendedoresDashboardPage({super.key});

  final List<Vendedor> vendedoresFake = [
    Vendedor(
      id: 1,
      nombre: "Ana García",
      email: "ana@ventas.com",
      role: "USER",
      ventasPorCategoria: {"COLLAR": 15, "PULSERA": 20, "ANILLO": 5},
    ),
    Vendedor(
      id: 2,
      nombre: "Carlos Ruiz",
      email: "carlos@ventas.com",
      role: "USER",
      ventasPorCategoria: {"COLLAR": 10, "PULSERA": 5, "ANILLO": 14},
    ),
    Vendedor(
      id: 3,
      nombre: "Laura Torres",
      email: "laura@ventas.com",
      role: "USER",
      ventasPorCategoria: {"COLLAR": 20, "PULSERA": 10, "ANILLO": 8},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Detectamos si es PC/portátil
        bool isDesktop = constraints.maxWidth >= 700;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Panel de Vendedores",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // GRID RESPONSIVE
              Expanded(
                child: GridView.builder(
                  itemCount: vendedoresFake.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio:
                        1.1, // Ajusta si quieres hacerlas más compactas
                  ),

                  itemBuilder: (context, index) {
                    final v = vendedoresFake[index];
                    return VendorCard(
                      vendedor: v,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendedorDetailPage(vendedor: v),
                          ),
                        );

                        // TODO: VendorDetailPage
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 690) return 1; // 📱 MÓVIL
    if (width < 1100) return 2; // 📱📲 TABLET
    if (width < 1500) return 3; // 🖥️ PC Estándar
    return 4; // 🖥️🖥️ Monitores grandes
  }
}
