import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/models/linea_pedido.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/models/cliente.dart';

import 'package:expositor_app/data/services/linea_pedido_service.dart';
import 'package:expositor_app/data/services/pedido_service.dart';
import 'package:expositor_app/data/services/producto_service.dart';
import 'package:expositor_app/data/services/cliente_service.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PedidoAdminDetailPage extends StatefulWidget {
  Pedido pedido;

  PedidoAdminDetailPage({super.key, required this.pedido});

  @override
  State<PedidoAdminDetailPage> createState() => _PedidoAdminDetailPageState();
}

class _PedidoAdminDetailPageState extends State<PedidoAdminDetailPage> {
  bool _showLines = false;
  bool _loading = false;
  List<LineaPedido> _lineas = [];

  final ProductoService productoService = ProductoService();
  final PedidoService pedidoService = PedidoService();
  final ClienteService clienteService = ClienteService();
  final LineaPedidoService lineapedidoService = LineaPedidoService();

  Cliente? _cliente;

  @override
  void initState() {
    super.initState();
    _loadCliente();
  }

  Future<void> _loadCliente() async {
    try {
      final cli = await clienteService.getClienteById(widget.pedido.idCliente);
      if (!mounted) return;
      setState(() {
        _cliente = cli;
      });
    } catch (_) {}
  }

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

  Future<void> _loadLineasPedido() async {
    setState(() => _loading = true);

    final result = await lineapedidoService.getLineasPedido(
      widget.pedido.idCliente,
      widget.pedido.id,
    );

    setState(() {
      _lineas = result;
      _showLines = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        title: Text(
          "Pedido #${pedido.id}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowInfo("ID del Pedido", pedido.id.toString()),
                _rowInfo(
                  "Cliente",
                  _cliente != null
                      ? "${_cliente!.nombre} - ${_cliente!.cif}"
                      : "Cargando...",
                ),
                _rowInfo("Fecha", formatFecha(pedido.fecha)),
                _rowInfo("Estado", pedido.cerrado ? "Cerrado" : "Abierto"),

                _rowInfo("Bruto total", "${pedido.brutoTotal} €"),
                _rowInfo("Base imponible", "${pedido.baseImponible} €"),
                _rowInfo("IVA", "${pedido.precioIva} €"),
                _rowInfo("Total final", "${pedido.total} €"),

                _rowInfo("Líneas", pedido.idLineaPedido.length.toString()),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C75EF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_showLines) {
                        setState(() => _showLines = false);
                      } else {
                        _loadLineasPedido();
                      }
                    },
                    child: Text(
                      _showLines ? "Ocultar líneas" : "Ver líneas del pedido",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_loading) const Center(child: CircularProgressIndicator()),

                if (_showLines && !_loading)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _lineas.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _AddLineaItem();

                        final linea = _lineas[index - 1];
                        return _LineaPedidoItem(linea: linea);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$title:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // ITEM DE LÍNEA (CON ICONO DE ELIMINAR)
  // -------------------------------------------------------------------
  Widget _LineaPedidoItem({required LineaPedido linea}) {
    final total = linea.precio * linea.cantidad;

    return GestureDetector(
      onDoubleTap: () => _showEditLineaDialog(linea),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FutureBuilder(
          future: productoService.getProducto(linea.idProducto),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (!snapshot.hasData) return const Text("Producto no encontrado");

            final Producto producto = snapshot.data!;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.descripcion,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Precio unitario: ${linea.precio.toStringAsFixed(2)} €",
                      ),
                      Text("Cantidad: ${linea.cantidad}"),
                      const SizedBox(height: 4),
                      Text(
                        "Total línea: ${total.toStringAsFixed(2)} €",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!widget.pedido.cerrado)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteLinea(linea),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // CONFIRMAR ELIMINACIÓN
  // -------------------------------------------------------------------
  void _confirmDeleteLinea(LineaPedido linea) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Eliminar línea",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Seguro que quieres eliminar esta línea del pedido?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Eliminar"),
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

  // -------------------------------------------------------------------
  // AÑADIR LÍNEA
  // -------------------------------------------------------------------
  Widget _AddLineaItem() {
    return GestureDetector(
      onTap: () => _showAddLineaDialog(),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
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
    );
  }

  // -------------------------------------------------------------------
  // DIALOGO AÑADIR LÍNEA
  // -------------------------------------------------------------------
  void _showAddLineaDialog() async {
    Producto? productoSeleccionado;
    TextEditingController unidadesCtrl = TextEditingController();
    TextEditingController precioCtrl = TextEditingController();

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
  // EDITAR LÍNEA (DOBLE TAP)
  // -------------------------------------------------------------------
  void _showEditLineaDialog(LineaPedido linea) async {
    final producto = await productoService.getProducto(linea.idProducto);

    TextEditingController unidadesCtrl = TextEditingController(
      text: linea.cantidad.toString(),
    );
    TextEditingController precioCtrl = TextEditingController(
      text: linea.precio.toString(),
    );

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
                "Editar línea",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto?.descripcion ?? "Producto",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: unidadesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Unidades",
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
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  child: const Text("Guardar cambios"),
                  onPressed: () async {
                    final cantidad = int.tryParse(unidadesCtrl.text);
                    final precio = double.tryParse(precioCtrl.text);

                    if (cantidad == null || precio == null) return;

                    final updated = await lineapedidoService.updateLineaPedido(
                      widget.pedido.idCliente,
                      widget.pedido.id,
                      linea.id,
                      cantidad,
                      precio,
                    );

                    Navigator.pop(dialogContext);

                    if (updated != null) await _refreshPedido();
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

  // -------------------------------------------------------------------
  // FORMATEAR FECHA
  // -------------------------------------------------------------------
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
