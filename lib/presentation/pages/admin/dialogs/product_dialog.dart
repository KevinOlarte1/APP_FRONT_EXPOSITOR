import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/models/categoria.dart';
import 'package:expositor_app/data/services/categoria_service.dart';

class ProductDialog extends StatefulWidget {
  final Producto? producto; // null = crear / != null = editar

  const ProductDialog({super.key, this.producto});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late TextEditingController nombreCtrl;
  late TextEditingController precioCtrl;

  List<Categoria> categorias = [];
  Categoria? categoriaSeleccionada;

  final CategoriaService categoriaService = CategoriaService();

  @override
  void initState() {
    super.initState();

    nombreCtrl = TextEditingController(
      text: widget.producto?.descripcion ?? "",
    );
    precioCtrl = TextEditingController(
      text: widget.producto != null ? widget.producto!.precio.toString() : "",
    );

    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final lista = await categoriaService.getCategorias();

    setState(() {
      categorias = lista;

      if (widget.producto != null) {
        // Buscar la categoría que coincida con el ID del producto
        categoriaSeleccionada = categorias.firstWhere(
          (c) => c.id == widget.producto!.categoriaId,
          orElse: () => categorias.first,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.producto != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: categorias.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? "Editar Producto" : "Crear Producto",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: nombreCtrl,
                    decoration: InputDecoration(
                      labelText: "Nombre",
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "PvP",
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<Categoria>(
                    value: categoriaSeleccionada,
                    decoration: InputDecoration(
                      labelText: "Categoría",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: categorias.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.nombre, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => categoriaSeleccionada = v);
                    },
                  ),

                  const SizedBox(height: 26),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancelar",
                          style: GoogleFonts.poppins(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (nombreCtrl.text.isEmpty ||
                              precioCtrl.text.isEmpty ||
                              categoriaSeleccionada == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Todos los campos son obligatorios",
                                ),
                              ),
                            );
                            return;
                          }

                          final producto = Producto(
                            id: widget.producto?.id ?? 0,
                            descripcion: nombreCtrl.text,
                            precio: double.tryParse(precioCtrl.text) ?? 0.0,
                            categoriaId:
                                categoriaSeleccionada!.id, // 🔥 correcto
                          );

                          Navigator.pop(context, producto);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C75EF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          isEdit ? "Guardar Cambios" : "Crear",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
