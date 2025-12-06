import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

import 'package:expositor_app/presentation/widget/cards/cliente_card.dart';
import 'package:expositor_app/presentation/pages/admin/cliente/cliente_details_admin_page.dart';

class ClientesAdminPage extends StatefulWidget {
  const ClientesAdminPage({super.key});

  @override
  State<ClientesAdminPage> createState() => _ClientesAdminPageState();
}

class _ClientesAdminPageState extends State<ClientesAdminPage> {
  final ClienteService _clienteService = ClienteService();
  final VendedorService _vendedorService = VendedorService();

  List<Cliente> allClients = [];
  List<Cliente> filteredClients = [];

  List<Vendedor> vendedores = [];
  Vendedor? selectedVendedor;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final lClientes = await _clienteService.getAllClientes();
    final lVendedores = await _vendedorService.getVendedores();

    setState(() {
      allClients = lClientes;
      filteredClients = lClientes;
      vendedores = lVendedores;
    });
  }

  // ------------------------
  // APLICAR FILTROS COMBINADOS
  // ------------------------
  void _applyFilters() {
    String q = _searchCtrl.text.toLowerCase().trim();

    List<Cliente> baseList;

    // Filtro por vendedor
    if (selectedVendedor != null) {
      baseList = allClients
          .where((c) => c.idVendedor == selectedVendedor!.id)
          .toList();
    } else {
      baseList = List.of(allClients);
    }

    // Filtro por buscador
    if (q.isEmpty) {
      setState(() => filteredClients = baseList);
      return;
    }

    setState(() {
      filteredClients = baseList.where((c) {
        final nombre = c.nombre.toLowerCase();
        final cif = c.cif.toLowerCase();
        return nombre.contains(q) || cif.contains(q);
      }).toList();
    });
  }

  void _filterByVendedor(Vendedor? vendedor) {
    setState(() => selectedVendedor = vendedor);
    _applyFilters();
  }

  void _filterBySearch(String q) {
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;

            // Tamaño responsive
            double maxTileWidth = 260;
            int crossAxisCount = (width / maxTileWidth).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===========================================================
                // FILTRO + BUSCADOR + DROPDOWN EN UNA MISMA FILA
                // ===========================================================
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isSmall =
                          constraints.maxWidth <
                          650; // 🔥 Ajusta aquí si quieres

                      if (isSmall) {
                        // ===========================================================
                        // MODO COLUMNA (pantallas pequeñas)
                        // ===========================================================
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Filtrar por vendedor",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // BUSCADOR
                            SizedBox(
                              height: 50,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: _filterBySearch,
                                decoration: InputDecoration(
                                  hintText: "Buscar por nombre o CIF...",
                                  suffixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // DROPDOWN VENDEDORES
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: DropdownButton<Vendedor?>(
                                underline: const SizedBox(),
                                value: selectedVendedor,
                                hint: Text(
                                  "Todos los vendedores",
                                  style: GoogleFonts.poppins(fontSize: 15),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      "Todos los vendedores",
                                      style: GoogleFonts.poppins(fontSize: 15),
                                    ),
                                  ),
                                  ...vendedores.map((v) {
                                    return DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        "${v.nombre} ${v.apellido}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) => _filterByVendedor(value),
                              ),
                            ),
                          ],
                        );
                      }

                      // ===========================================================
                      // MODO FILA (pantallas grandes)
                      // ===========================================================
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Filtrar por vendedor",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(width: 30),

                          // BUSCADOR
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: _filterBySearch,
                                decoration: InputDecoration(
                                  hintText: "Buscar por nombre o CIF...",
                                  suffixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 30),

                          // DROPDOWN VENDEDORES
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: DropdownButton<Vendedor?>(
                              underline: const SizedBox(),
                              value: selectedVendedor,
                              hint: Text(
                                "Todos los vendedores",
                                style: GoogleFonts.poppins(fontSize: 15),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    "Todos los vendedores",
                                    style: GoogleFonts.poppins(fontSize: 15),
                                  ),
                                ),
                                ...vendedores.map((v) {
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      "${v.nombre} ${v.apellido}",
                                      style: GoogleFonts.poppins(fontSize: 15),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) => _filterByVendedor(value),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ===========================================================
                // GRID RESPONSIVE
                // ===========================================================
                Expanded(
                  child: filteredClients.isEmpty
                      ? Center(
                          child: Text(
                            "No hay clientes disponibles",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(top: 10),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.80, // cartas compactas
                              ),
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            final cliente = filteredClients[index];

                            return CardCliente(
                              cliente: cliente,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClienteDetailsAdminPage(
                                      cliente: cliente,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
