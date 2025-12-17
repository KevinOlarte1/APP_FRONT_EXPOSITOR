import 'package:expositor_app/data/services/parametros_globales_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/models/linea_pedido.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/models/cliente.dart';

import 'package:expositor_app/data/services/pedido_service.dart';
import 'package:expositor_app/data/services/linea_pedido_service.dart';
import 'package:expositor_app/data/services/producto_service.dart';
import 'package:expositor_app/data/services/cliente_service.dart';

class PedidoAdminDetailPage extends StatefulWidget {
  Pedido pedido;

  PedidoAdminDetailPage({super.key, required this.pedido});

  @override
  State<PedidoAdminDetailPage> createState() => _PedidoAdminDetailPageState();
}

class _PedidoAdminDetailPageState extends State<PedidoAdminDetailPage> {
  final ClienteService clienteService = ClienteService();
  final PedidoService pedidoService = PedidoService();
  final LineaPedidoService lineapedidoService = LineaPedidoService();
  final ProductoService productoService = ProductoService();
  final ParametrosGlobalesService paramService = ParametrosGlobalesService();

  Cliente? cliente;
  List<LineaPedido> lineas = [];
  bool loadingLineas = true;
  int? filtroGrupo = null; // null = sin filtro
  List<LineaPedido> lineasFiltradas = [];
  int grupoMaxConfig = 1; // Para construir el selector

  @override
  void initState() {
    super.initState();

    print("Pedido entrado -------------------------");
    print("idPedido: ${widget.pedido.id}");
    print("Lineas");
    for (int i in widget.pedido.idLineaPedido) {
      print(i);
    }

    _loadAll();
  }

  Future<void> _loadAll() async {
    print("Entra");
    setState(() {
      loadingLineas = true;
    });
    print("Entra1");

    await _loadCliente();

    await _loadLineasPedido();

    grupoMaxConfig = await paramService.getGrupoMax();

    _aplicarFiltro();
  }

  void _aplicarFiltro() {
    setState(() {
      if (filtroGrupo == null) {
        lineasFiltradas = List.from(lineas);
      } else {
        lineasFiltradas = lineas.where((l) => l.grupo == filtroGrupo).toList();
      }
    });
  }

  // CARGAR CLIENTE
  Future<void> _loadCliente() async {
    final cli = await clienteService.getClienteById(widget.pedido.idCliente);
    setState(() => cliente = cli);
  }

  // CARGAR LÍNEAS
  Future<void> _loadLineasPedido() async {
    setState(() => loadingLineas = true);

    final result = await lineapedidoService.getLineasPedido(
      widget.pedido.idCliente,
      widget.pedido.id,
    );

    setState(() {
      lineas = result;
      loadingLineas = false;
    });

    _aplicarFiltro();
  }

  // REFRESCAR PEDIDO + LÍNEAS + CLIENTE
  Future<void> _refreshPedido() async {
    final updated = await pedidoService.getPedido(
      idCliente: widget.pedido.idCliente,
      idPedido: widget.pedido.id,
    );

    if (updated != null) {
      setState(() => widget.pedido = updated);
    }

    await _loadLineasPedido();
    await _loadCliente();
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        centerTitle: true,
        title: Text(
          "Pedido #${pedido.id}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          // ---------- ICONO ----------
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ---------- TÍTULO ----------
          Center(
            child: Text(
              "Pedido #${pedido.id}",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ---------- FECHA ----------
          Center(
            child: Text(
              formatFecha(pedido.fecha),
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 30),

          if (cliente != null)
            _buildInfoCard(pedido, cliente!)
          else
            const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 30),

          _buildLineasCard(),
        ],
      ),
    );
  }

  // ===========================================================
  //                  CARD INFORMACIÓN PRINCIPAL
  // ===========================================================
  Widget _buildInfoCard(Pedido pedido, Cliente cliente) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ----- Columna izquierda -----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleItem("Bruto total:", "${pedido.brutoTotal} €"),
                  const SizedBox(height: 16),
                  _titleItem(
                    "Base imponible:",
                    "${pedido.baseImponible} €   •   ${pedido.descuento}%",
                  ),
                  const SizedBox(height: 16),
                  _titleItem(
                    "IVA:",
                    "${pedido.precioIva} €   •   ${pedido.iva}%",
                  ),
                  const SizedBox(height: 16),
                  _titleItem("Total final:", "${pedido.total} €"),
                  const SizedBox(height: 16),
                  _titleItem(
                    "Num de líneas:",
                    pedido.idLineaPedido.length.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 40),

            // ----- Columna derecha -----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleItem("ID del pedido:", pedido.id.toString()),
                  const SizedBox(height: 16),
                  _titleItem("Cliente:", "${cliente.nombre} - ${cliente.cif}"),
                  const SizedBox(height: 16),
                  _titleItem("Fecha:", formatFecha(pedido.fecha)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // DIALOGO AÑADIR LÍNEA
  // -------------------------------------------------------------------
  Widget _buildAddLineaButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showAddLineaDialog,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "Añadir línea",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  //                    CARD LÍNEAS DEL PEDIDO
  // ===========================================================
  Widget _buildLineasCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- TÍTULO ----------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- TÍTULO ----------
                      Text(
                        "Gestión de líneas",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ------------------ FILTRO POR GRUPO ------------------
                      // ------------------ FILTRO POR GRUPO ------------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                          color: Colors.grey.shade100,
                        ),
                        width: 160, // Caja pequeña elegante
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: filtroGrupo,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("Todos"),
                              ),
                              ...List.generate(
                                grupoMaxConfig,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text("Grupo ${i + 1}"),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                filtroGrupo = value; // cambia filtro
                                _aplicarFiltro(); // actualiza lista filtrada
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---------- BOTÓN PARA PANTALLAS PEQUEÑAS ----------
                      if (MediaQuery.of(context).size.width < 500)
                        _buildResponsiveActionButton(),
                    ],
                  ),
                ),

                // ---------- BOTÓN PARA PANTALLAS GRANDES ----------
                if (MediaQuery.of(context).size.width >= 500)
                  _buildResponsiveActionButton(),
              ],
            ),

            const SizedBox(height: 18),

            // ---------- BOTÓN AÑADIR LÍNEA ----------
            if (!widget.pedido.cerrado) _buildAddLineaButton(),

            if (!widget.pedido.cerrado)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 1),
              ),

            // ---------- LÍNEAS ----------
            if (loadingLineas)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (lineas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "No hay líneas registradas",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < lineasFiltradas.length; i++) ...[
                    _buildLineaReal(lineasFiltradas[i]),
                    if (i < lineasFiltradas.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 1),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showAddLineaDialog() async {
    Producto? productoSeleccionado;
    TextEditingController unidadesCtrl = TextEditingController();
    TextEditingController precioCtrl = TextEditingController();

    int grupoSeleccionado = filtroGrupo ?? 1;
    int grupoMax = 1;

    grupoMax = await paramService.getGrupoMax();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Añadir línea al pedido",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final seleccionado = await _showProductoSelector();
                      if (seleccionado != null) {
                        setStateDialog(() {
                          productoSeleccionado = seleccionado;
                          precioCtrl.text = seleccionado.precio.toString();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productoSeleccionado?.descripcion ??
                                "Seleccionar producto",
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: unidadesCtrl,
                    decoration: InputDecoration(
                      labelText: "Unidades",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: precioCtrl,
                    decoration: InputDecoration(
                      labelText: "Precio unitario",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<int>(
                    value: grupoSeleccionado,
                    decoration: InputDecoration(
                      labelText: "Grupo",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: List.generate(
                      grupoMax,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text("Grupo ${i + 1}"),
                      ),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        grupoSeleccionado = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  child: const Text("Guardar"),
                  onPressed: () async {
                    if (productoSeleccionado == null ||
                        unidadesCtrl.text.isEmpty ||
                        precioCtrl.text.isEmpty)
                      return;

                    final nuevaLinea = await lineapedidoService.addLineaPedido(
                      widget.pedido.idCliente,
                      widget.pedido.id,
                      productoSeleccionado!.id,
                      int.parse(unidadesCtrl.text),
                      double.parse(precioCtrl.text),
                      grupoSeleccionado,
                    );

                    Navigator.pop(dialogContext);

                    if (nuevaLinea != null) await _refreshPedido();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // SELECTOR DE PRODUCTOS
  // -------------------------------------------------------------------
  Future<Producto?> _showProductoSelector() async {
    List<Producto> productos = await productoService.getAllProductos();
    List<Producto> filtrados = List.from(productos);
    TextEditingController searchCtrl = TextEditingController();

    return showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: "Buscar por nombre o categoría",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setStateSheet(() {
                        final query = value.toLowerCase();
                        filtrados = productos.where((p) {
                          final nameMatch = p.descripcion
                              .toLowerCase()
                              .contains(query);
                          final catMatch = (p.categoria ?? "")
                              .toLowerCase()
                              .contains(query);
                          return nameMatch || catMatch;
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final p = filtrados[index];

                        return ListTile(
                          title: Text(
                            p.descripcion,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${p.precio.toStringAsFixed(2)} €",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              if (p.categoria != null)
                                Text(
                                  "Categoría: ${p.categoria}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  //                    ITEM DE LÍNEA REAL
  // ===========================================================
  Widget _buildLineaReal(LineaPedido linea) {
    return GestureDetector(
      onDoubleTap: widget.pedido.cerrado
          ? null
          : () => _showEditLineaDialog(linea),
      child: FutureBuilder(
        future: productoService.getProducto(linea.idProducto),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final Producto producto = snapshot.data!;
          final String totalLinea = (linea.precio * linea.cantidad)
              .toStringAsFixed(2);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- ICONO PRODUCTO ----------
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.blue,
                  size: 22,
                ),
              ),

              const SizedBox(width: 15),

              // ---------- DATOS DE LA LÍNEA ----------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.descripcion,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Cantidad: ${linea.cantidad}",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),

                    Text(
                      "Precio unitario: ${linea.precio.toStringAsFixed(2)} €",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Total línea: $totalLinea €",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- BOTÓN BORRAR ----------
              if (!widget.pedido.cerrado)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteLinea(linea),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showEditLineaDialog(LineaPedido linea) async {
    final producto = await productoService.getProducto(linea.idProducto);

    TextEditingController cantidadCtrl = TextEditingController(
      text: linea.cantidad.toString(),
    );
    TextEditingController precioCtrl = TextEditingController(
      text: linea.precio.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Editar línea",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto?.descripcion ?? "Sin descripción",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Cantidad",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: precioCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Precio unitario",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancelar", style: GoogleFonts.poppins()),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Guardar", style: GoogleFonts.poppins()),
              onPressed: () async {
                final cantidad = int.tryParse(cantidadCtrl.text);
                final precio = double.tryParse(precioCtrl.text);

                if (cantidad == null || precio == null) return;

                Navigator.pop(dialogContext);

                final updated = await lineapedidoService.updateLineaPedido(
                  widget.pedido.idCliente,
                  widget.pedido.id,
                  linea.id,
                  cantidad,
                  precio,
                );

                if (updated != null) {
                  await _refreshPedido();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ===========================================================
  //                    CONFIRMAR BORRADO
  // ===========================================================
  void _confirmDeleteLinea(LineaPedido linea) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Eliminar línea",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Seguro que quieres eliminar esta línea?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: Text("Cancelar", style: GoogleFonts.poppins()),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Eliminar", style: GoogleFonts.poppins()),
              onPressed: () async {
                Navigator.pop(context);

                final ok = await lineapedidoService.deleteLineaPedido(
                  widget.pedido.idCliente,
                  widget.pedido.id,
                  linea.id,
                );

                if (ok) {
                  await _refreshPedido();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al eliminar la línea"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmCerrarPedido() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Cerrar pedido",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Seguro que quieres cerrar este pedido?\n\nUna vez cerrado, no podrás modificar líneas.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar", style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);

                final ok = await pedidoService.cerrarPedido(
                  widget.pedido.idCliente,
                  widget.pedido.id,
                );

                if (ok) {
                  await _refreshPedido();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al cerrar el pedido"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                "Cerrar",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveActionButton() {
    return widget.pedido.cerrado
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _descargarPedidoPdf,
            child: Text(
              "Descargar PDF",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _confirmCerrarPedido,
            child: Text(
              "Cerrar pedido",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
  }

  Future<void> _descargarPedidoPdf() async {
    try {
      /* await pedidoService.descargarPedido(
        widget.pedido.idCliente,
        widget.pedido.id,
      );*/
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF descargado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al descargar el PDF"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===========================================================
  //                    FORMATEAR FECHA
  // ===========================================================
  String formatFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (_) {
      return fechaISO;
    }
  }
}
