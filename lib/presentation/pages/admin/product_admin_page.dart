import 'package:expositor_app/data/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/enums/categoria_product.dart';
import 'dialogs/product_dialog.dart';

class ProductAdminPage extends StatefulWidget {
  const ProductAdminPage({super.key});

  @override
  State<ProductAdminPage> createState() => _ProductAdminPageState();
}

class _ProductAdminPageState extends State<ProductAdminPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ProductoService _productoService = ProductoService();

  List<Producto> _all = [];
  List<Producto> _filtered = [];

  @override
  void initState() {
    super.initState();

    _loadProductos();
    _filtered = List.of(_all);

    _searchCtrl.addListener(_applyFilter);
  }

  void _loadProductos() async {
    final productos = await _productoService.getAllProductos();
    setState(() {
      _all = productos;
      _filtered = productos;
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  // FILTRO
  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(_all);
      } else {
        _filtered = _all.where((p) {
          final categoriaStr = p.categoria
              .toString()
              .split('.')
              .last
              .toLowerCase();
          return p.descripcion.toLowerCase().contains(q) ||
              categoriaStr.contains(q) ||
              p.precio.toString().contains(q) ||
              p.id.toString().contains(q);
        }).toList();
      }
    });
  }

  void _showCreateOrEditDialog({Producto? producto}) async {
    final result = await showDialog(
      context: context,
      builder: (_) => ProductDialog(),
    );

    if (result != null && result is Producto) {
      if (producto == null) {
        final ok = await ProductoService().createProducto(result);

        if (ok) {
          // Recargar productos desde la API
          final productos = await ProductoService().getAllProductos();
          setState(() {
            _all = productos;
            _filtered = productos;
          });
        }
      } else {
        // EDITAR
        final ok = await ProductoService().updateProducto(result);
        if (ok) {
          setState(() {
            final index = _all.indexWhere((p) => p.id == producto.id);
            if (index != -1) {
              _all[index] = result;
              _filtered = List.of(_all);
            }
          });
        }
      }
    }
  }

  // ===================================================
  //                     UI
  // ===================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF), // Azul corporativo
        elevation: 0,
        centerTitle: false,

        title: Text(
          "Administrar Productos",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white, // 🔥 Texto blanco
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 Iconos blancos (flecha atrás, menú…)
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.only(top: 20),

        child: Column(
          children: [
            // TÍTULO + BOTÓN CREAR
            Align(
              child: ElevatedButton.icon(
                onPressed: () => _showCreateOrEditDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  "CREAR",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C75EF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BUSCADOR
            Align(
              child: SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Buscar...",
                    suffixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // CABECERA TABLA
            // ================= TABLA ESTÁTICA CON SCROLL HORIZONTAL =================
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Center(
                  child: Container(
                    width: 900, // 👈 ancho fijo de la tabla
                    child: Column(
                      children: [
                        // CABECERA
                        Container(
                          width: 900,
                          color: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: const [
                              _HeaderCell("ID", flex: 1),
                              _HeaderCell("NOMBRE", flex: 4),
                              _HeaderCell("PRECIO UNITARIO", flex: 3),
                              _HeaderCell("CATEGORÍA", flex: 3),
                              _HeaderCell("", flex: 1),
                            ],
                          ),
                        ),

                        // FILAS
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final p = _filtered[i];
                              final categoriaStr = p.categoria
                                  .toString()
                                  .split('.')
                                  .last;

                              return GestureDetector(
                                onDoubleTap: () =>
                                    _showCreateOrEditDialog(producto: p),
                                child: Container(
                                  width: 900, // 👈 mismo ancho fijo de la tabla
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _RowCell("${p.id}", flex: 1),
                                      _RowCell(p.descripcion, flex: 4),
                                      _RowCell("${p.precio} €", flex: 3),
                                      _RowCell(categoriaStr, flex: 3),
                                      Expanded(
                                        flex: 1,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          tooltip: "Eliminar producto",
                                          onPressed: () => _deleteProducto(p),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProducto(Producto p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: Text(
          "¿Seguro que quieres eliminar el producto \"${p.descripcion}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await _productoService.deleteProducto(p.id);

    if (ok) {
      setState(() {
        _all.removeWhere((e) => e.id == p.id);
        _filtered.removeWhere((e) => e.id == p.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Producto eliminado")));
    }
  }
}

// ===================================================
//            WIDGET CELDAS CABECERA Y FILAS
// ===================================================

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

class _RowCell extends StatelessWidget {
  final String text;
  final int flex;

  const _RowCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.poppins(fontSize: 14)),
    );
  }
}
