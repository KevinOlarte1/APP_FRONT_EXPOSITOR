import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/pedido_service.dart';
import 'package:expositor_app/presentation/pages/admin/pedido_detail_page.dart';
import 'package:expositor_app/presentation/widget/cards/pedido_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'dart:math' as math;

class ClienteDetailsPage extends StatefulWidget {
  final Cliente cliente;

  const ClienteDetailsPage({super.key, required this.cliente});

  @override
  State<ClienteDetailsPage> createState() => _ClienteDetailsAdminPageState();
}

class _ClienteDetailsAdminPageState extends State<ClienteDetailsPage> {
  final VendedorService vendedorService = VendedorService();
  final ClienteService clienteService = ClienteService();
  final PedidoService pedidoService = PedidoService();
  final SecureStorageService secureStorage = SecureStorageService();

  late Future<Vendedor?> futureVendedor;
  late Cliente _cliente;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    futureVendedor = vendedorService.getById(widget.cliente.idVendedor);
  }

  // ============================================================
  // CREAR PEDIDO USANDO VALORES POR DEFECTO (IVA + DESCUENTO)
  // ============================================================
  Future<void> _crearPedido() async {
    final nuevo = await pedidoService.addPedido(idCliente: widget.cliente.id);

    if (nuevo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Error al crear pedido")));
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            PedidoDetailPage(pedido: nuevo),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.2, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  // ============================================================
  // CARD DE CREAR PEDIDO
  // ============================================================
  Widget _buildAddPedidoCard() {
    return InkWell(
      onTap: _crearPedido,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, size: 48, color: Color(0xFF3C75EF)),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD UI COMPLETA
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final cliente = _cliente;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        title: Text(
          "Cliente: ${cliente.nombre}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, true); // ✅ avisa que hay cambios
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -----------------------------------------------------------
            // FOTO + INFO BÁSICA
            // -----------------------------------------------------------
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue.shade200,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cliente.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cliente.cif,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // -----------------------------------------------------------
            // CARD 1 — INFO CLIENTE
            // -----------------------------------------------------------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Información del Cliente",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          tooltip: "Actualizar cliente",
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF3C75EF),
                          ),
                          onPressed: () async {
                            final updated = await _showUpdateClienteDialog(
                              context,
                              _cliente,
                              isAdmin: Session.isAdmin,
                            );
                            if (updated != null) {
                              setState(() {
                                _cliente =
                                    updated; // ✅ ahora sí cambia lo que se pinta
                                futureVendedor = vendedorService.getById(
                                  updated.idVendedor,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _infoRow("ID Cliente", cliente.id.toString()),
                    _infoRow("Nombre", cliente.nombre),
                    _infoRow("CIF", cliente.cif),
                    _infoRow(
                      "Teléfono",
                      cliente.telefono.isNotEmpty ? cliente.telefono : "—",
                    ),
                    _infoRow(
                      "Correo",
                      cliente.email.isNotEmpty ? cliente.email : "—",
                    ),

                    const SizedBox(height: 10),

                    FutureBuilder<Vendedor?>(
                      future: futureVendedor,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _infoRow("Vendedor asociado", "Cargando...");
                        }
                        if (!snapshot.hasData) {
                          return _infoRow("Vendedor asociado", "No disponible");
                        }

                        final v = snapshot.data!;
                        return _infoRow(
                          "Vendedor asociado",
                          "${v.nombre} ${v.apellido} — ${v.email}",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------
            // CARD 2 — GRAFICA DE INGRESO ANUAL
            // -----------------------------------------------------------
            /*
            _buildGraficaIngresos(),

            const SizedBox(height: 20), */

            // -----------------------------------------------------------
            // CARD 3 — PEDIDOS + BOTÓN CREAR PEDIDO
            // -----------------------------------------------------------
            _buildPedidosConCrear(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GRAFICA INGRESOS (SEPARADA PARA LIMPIEZA)
  // ============================================================
  Widget _buildGraficaIngresos() {
    return FutureBuilder<Map<String, double>>(
      future: clienteService.getIngresoAnual(_cliente.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No hay datos de ingresos anuales.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final years = data.keys.toList();
        final values = data.values.toList();
        final maxValue = values.reduce((a, b) => a > b ? a : b);

        // Evita maxY = 0 (si todo es 0, pinta igualmente la gráfica sin romper)
        final safeMax = maxValue <= 0 ? 1.0 : maxValue;

        // Intervalo SIEMPRE > 0
        final safeInterval = math.max(1.0, safeMax / 5);
        final allZero = values.every((v) => v == 0);
        /*
        if (allZero) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Este cliente aún no tiene ingresos.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        } */
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Estadísticas — Ingreso Anual",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 260,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width:
                          (data.length * 120).toDouble() <
                              MediaQuery.of(context).size.width
                          ? MediaQuery.of(context).size.width
                          : (data.length * 120).toDouble(),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                        ), // ✅ aire tooltip
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.start,
                            minY: 0,
                            maxY: safeMax * 1.25,

                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                fitInsideHorizontally: true, // ✅
                                fitInsideVertically: true, // ✅
                                tooltipRoundedRadius: 12,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                tooltipMargin: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      final year = years[group.x.toInt()];
                                      final value = values[group.x.toInt()];

                                      return BarTooltipItem(
                                        '$year\n',
                                        const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                '${value.toStringAsFixed(2)} €',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                              ),
                            ),

                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),

                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                  reservedSize: 12, // ✅ espacio superior
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= years.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        years[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            barGroups: List.generate(
                              data.length,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: values[i],
                                    width: 35,
                                    borderRadius: BorderRadius.circular(6),
                                    color: const Color(0xFF3C75EF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PEDIDOS + BOTÓN NUEVO PEDIDO
  // ============================================================
  Widget _buildPedidosConCrear() {
    final cliente = _cliente;

    return FutureBuilder<List<Pedido>>(
      future: pedidoService.getPedidosByClienteAdmin(cliente.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pedidos = snapshot.data ?? [];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pedidos del Cliente",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // ===== CONTADOR DE PEDIDOS =====
                if (pedidos.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(
                            0.15,
                          ), // MISMO COLOR QUE PEDIDO ABIERTO
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "ABIERTO: ${pedidos.where((p) => p.cerrado == false).length}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.orange, // MISMO COLOR QUE PEDIDO ABIERTO
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(
                            0.15,
                          ), // MISMO COLOR QUE PEDIDO CERRADO
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "CERRADO: ${pedidos.where((p) => p.cerrado == true).length}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.green, // MISMO COLOR QUE PEDIDO CERRADO
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // BOTÓN CREAR PEDIDO
                _buildAddPedidoCard(),

                const SizedBox(height: 20),

                if (pedidos.isEmpty)
                  const Text(
                    "Este cliente no tiene pedidos.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double width = constraints.maxWidth;

                      int crossAxisCount = 1;
                      if (width > 600) crossAxisCount = 2;
                      if (width > 1000) crossAxisCount = 3;

                      return GridView.builder(
                        itemCount: pedidos.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: _pedidoCardHeight(
                            pedidos,
                            crossAxisCount,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final pedido = pedidos[index];
                          return PedidoCard(
                            pedido: pedido,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PedidoDetailPage(pedido: pedido),
                                ),
                              ).then((_) {
                                setState(
                                  () {},
                                ); // 🔥 vuelve a ejecutar los FutureBuilder y recarga todo
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _pedidoCardHeight(List<Pedido> pedidos, int crossAxisCount) {
    final hasAnyComment = pedidos.any((p) => p.comentario.trim().isNotEmpty);

    // cuanto más columnas, más estrecha la card -> más filas de chips -> más alto
    if (crossAxisCount >= 3) return 370;
    if (crossAxisCount == 2) return 390;

    return hasAnyComment ? 360 : 320; // 1 columna
  }

  // ============================================================
  // FILA INFO
  // ============================================================
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<Cliente?> _showUpdateClienteDialog(
    BuildContext context,
    Cliente cliente, {
    required bool isAdmin, // 👈 pásalo desde tu estado de auth
  }) async {
    final formKey = GlobalKey<FormState>();

    final nombreCtrl = TextEditingController(text: cliente.nombre);
    final cifCtrl = TextEditingController(text: cliente.cif);
    final telCtrl = TextEditingController(text: cliente.telefono);
    final emailCtrl = TextEditingController(text: cliente.email);

    List<Vendedor> vendedores = [];
    int? selectedIdVendedor = cliente.idVendedor;

    return showDialog<Cliente?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Widget buildForm({List<Vendedor>? vendedoresData}) {
              vendedores = vendedoresData ?? vendedores;

              // Solo si admin y hay vendedores, asegura que selected exista
              if (isAdmin &&
                  vendedores.isNotEmpty &&
                  !vendedores.any((v) => v.id == selectedIdVendedor)) {
                selectedIdVendedor = vendedores.first.id;
              }

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: "Nombre"),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Requerido"
                            : null,
                      ),
                      TextFormField(
                        controller: cifCtrl,
                        decoration: const InputDecoration(labelText: "CIF"),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Requerido"
                            : null,
                      ),
                      TextFormField(
                        controller: telCtrl,
                        decoration: const InputDecoration(
                          labelText: "Teléfono",
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: "Correo"),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      // ✅ SOLO ADMIN ve el desplegable
                      if (isAdmin) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedIdVendedor,
                          decoration: const InputDecoration(
                            labelText: "Vendedor",
                          ),
                          items: (vendedoresData ?? vendedores)
                              .map(
                                (v) => DropdownMenuItem<int>(
                                  value: v.id,
                                  child: Text("${v.nombre} ${v.apellido}"),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setLocalState(() => selectedIdVendedor = value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              title: const Text("Actualizar cliente"),
              content: SizedBox(
                width: 420,

                // ✅ Si NO es admin, NO llamamos a getVendedores()
                child: isAdmin
                    ? FutureBuilder<List<Vendedor>>(
                        future: vendedorService.getVendedores(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final data = snapshot.data ?? [];
                          return buildForm(vendedoresData: data);
                        },
                      )
                    : buildForm(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    final actualizado = Cliente(
                      id: cliente.id,
                      nombre: nombreCtrl.text.trim(),
                      cif: cifCtrl.text.trim(),
                      telefono: telCtrl.text.trim(),
                      email: emailCtrl.text.trim(),

                      // ✅ si NO es admin, mantenemos el vendedor original
                      idVendedor: isAdmin
                          ? (selectedIdVendedor ?? cliente.idVendedor)
                          : cliente.idVendedor,

                      idPedidos: cliente.idPedidos,
                      pedidosCerrados: cliente.pedidosCerrados,
                      pedidosAbiertos: cliente.pedidosAbiertos,
                    );

                    final ok = await clienteService.update(actualizado);
                    if (!context.mounted) return;

                    if (ok == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("❌ No se pudo actualizar el cliente"),
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Cliente actualizado")),
                    );
                    Navigator.pop(context, ok);
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
