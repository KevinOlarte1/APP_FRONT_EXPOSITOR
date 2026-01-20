import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/presentation/widget/cards/vendor_card.dart';
import 'package:expositor_app/presentation/pages/admin/vendedor_detail_page.dart';

class VendedoresDashboardPage extends StatefulWidget {
  const VendedoresDashboardPage({super.key});

  @override
  State<VendedoresDashboardPage> createState() =>
      _VendedoresDashboardPageState();
}

class _VendedoresDashboardPageState extends State<VendedoresDashboardPage> {
  final VendedorService _service = VendedorService();

  List<Vendedor> vendedores = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadVendedores();
  }

  Future<void> _loadVendedores() async {
    final lista = await _service.getVendedores();

    setState(() {
      if (lista.isNotEmpty) {
        vendedores = lista;
      } else {
        vendedores = List.empty(); // fallback
      }
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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

              if (loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: GridView.builder(
                    itemCount: vendedores.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final v = vendedores[index];
                      return VendorCard(
                        vendedor: v,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VendedorDetailPage(vendedor: v, title: 1),
                            ),
                          );
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
    if (width < 690) return 1; // Móvil
    if (width < 1100) return 2; // Tablet
    if (width < 1500) return 3; // PC estándar
    return 4; // Pantallas grandes
  }
}
