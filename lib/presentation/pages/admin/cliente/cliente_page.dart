import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

import 'package:expositor_app/presentation/widget/cards/cliente_card.dart';
import 'package:expositor_app/presentation/pages/admin/cliente/cliente_details_page.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

// ✅ NUEVO: Session para saber si es admin
import 'package:expositor_app/core/session/session.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteService _clienteService = ClienteService();
  final VendedorService _vendedorService = VendedorService();

  final bool _isAdmin = Session.isAdmin;

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
    // ✅ Siempre cargamos clientes
    final lClientes = await _clienteService.getAllClientes();

    // ✅ SOLO ADMIN carga vendedores
    if (_isAdmin) {
      final lVendedores = await _vendedorService.getVendedores();

      setState(() {
        allClients = lClientes;
        filteredClients = lClientes;
        vendedores = lVendedores;
      });
    } else {
      setState(() {
        allClients = lClientes;
        filteredClients = lClientes;
        vendedores = []; // por claridad
        selectedVendedor = null;
      });
    }
  }

  // ------------------------
  // APLICAR FILTROS COMBINADOS
  // ------------------------
  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();

    List<Cliente> baseList;

    // ✅ Filtro por vendedor SOLO si es admin
    if (_isAdmin && selectedVendedor != null) {
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
            final width = constraints.maxWidth;

            // Tamaño responsive
            const maxTileWidth = 260.0;
            int crossAxisCount = (width / maxTileWidth).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===========================================================
                // FILTRO + BUSCADOR + (DROPDOWN SOLO ADMIN)
                // ===========================================================
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isSmall = constraints.maxWidth < 650;

                      // ==========================
                      // USER (NO ADMIN): SOLO BUSCADOR
                      // ==========================
                      if (!_isAdmin) {
                        return SizedBox(
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
                        );
                      }

                      // ==========================
                      // ADMIN: BUSCADOR + DROPDOWN
                      // ==========================
                      if (isSmall) {
                        // MODO COLUMNA (pantallas pequeñas)
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

                            // DROPDOWN VENDEDORES (ADMIN)
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

                      // MODO FILA (pantallas grandes)
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

                          // DROPDOWN VENDEDORES (ADMIN)
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
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.80,
                    ),
                    itemCount: filteredClients.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCrearClienteCard();
                      }

                      final cliente = filteredClients[index - 1];

                      return CardCliente(
                        cliente: cliente,

                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClienteDetailsPage(cliente: cliente),
                            ),
                          );

                          // ✅ SIEMPRE refrescar al volver
                          await _loadAll();
                          _applyFilters(); // mantiene buscador + filtro vendedor
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

  Widget _buildCrearClienteCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _irCrearCliente();
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.add, size: 32, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              const Text(
                "Crear Cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Añadir un nuevo cliente al sistema",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _irCrearCliente() {
    final formKey = GlobalKey<FormState>();

    final TextEditingController nombreController = TextEditingController();
    final TextEditingController cifController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    Vendedor? vendedorSeleccionado;
    String telefonoCompleto = '';

    bool emailValido(String email) {
      final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      return regex.hasMatch(email);
    }

    bool cifValido(String cif) {
      final value = cif.trim().toUpperCase();
      if (value.isEmpty) return false;

      // Validación básica: 1 letra opcional + números/letras mínimos
      final regex = RegExp(r'^[A-Z]?[A-Z0-9]{6,15}$');
      return regex.hasMatch(value);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Crear Cliente"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Nombre del cliente",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final nombre = value?.trim() ?? '';
                          if (nombre.isEmpty) {
                            return "Introduce el nombre del cliente";
                          }
                          if (nombre.length < 2) {
                            return "El nombre es demasiado corto";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: cifController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: "CIF",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final cif = value?.trim() ?? '';
                          if (cif.isEmpty) {
                            return "Introduce el CIF";
                          }
                          if (!cifValido(cif)) {
                            return "Introduce un CIF válido";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      IntlPhoneField(
                        initialCountryCode: 'ES',
                        disableLengthCheck: false,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          hintText: '612345678',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (phone) {
                          telefonoCompleto = phone.completeNumber;
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.trim().isEmpty) {
                            return 'Introduce el teléfono';
                          }

                          final soloNumero = phone.number.trim();
                          if (soloNumero.length < 7 || soloNumero.length > 15) {
                            return 'Introduce un número válido';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Correo electrónico",
                          hintText: "cliente@empresa.com",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return "Introduce el correo electrónico";
                          }
                          if (!emailValido(email)) {
                            return "Introduce un correo válido";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      if (_isAdmin)
                        DropdownButtonFormField<Vendedor>(
                          value: vendedorSeleccionado,
                          decoration: const InputDecoration(
                            labelText: "Seleccionar vendedor",
                            border: OutlineInputBorder(),
                          ),
                          items: vendedores.map((v) {
                            return DropdownMenuItem<Vendedor>(
                              value: v,
                              child: Text("${v.nombre} ${v.apellido}"),
                            );
                          }).toList(),
                          validator: (value) {
                            if (_isAdmin && value == null) {
                              return "Debes seleccionar un vendedor";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setStateDialog(() {
                              vendedorSeleccionado = value;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final nombre = nombreController.text.trim();
                    final cif = cifController.text.trim().toUpperCase();
                    final email = emailController.text.trim();

                    if (telefonoCompleto.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Introduce un teléfono válido"),
                        ),
                      );
                      return;
                    }

                    final int? idVendedor = _isAdmin
                        ? vendedorSeleccionado!.id
                        : Session.userId;

                    final nuevo = await _clienteService.addCliente(
                      nombre,
                      cif,
                      idVendedor,
                      telefonoCompleto,
                      email,
                    );

                    if (nuevo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al crear cliente")),
                      );
                      return;
                    }

                    setState(() {
                      allClients.insert(0, nuevo);
                    });
                    _applyFilters();

                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClienteDetailsPage(cliente: nuevo),
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cliente creado correctamente"),
                      ),
                    );
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
