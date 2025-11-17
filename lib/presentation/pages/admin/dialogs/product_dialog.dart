import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/enums/categoria_product.dart';

class ProductDialog extends StatefulWidget {
  final Producto? producto; // null = crear / != null = editar

  const ProductDialog({super.key, this.producto});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late TextEditingController nombreCtrl;
  late TextEditingController precioCtrl;
  CategoriaProducto? categoriaSeleccionada;

  @override
  void initState() {
    super.initState();

    nombreCtrl = TextEditingController(
      text: widget.producto?.descripcion ?? "",
    );
    precioCtrl = TextEditingController(
      text: widget.producto != null ? widget.producto!.precio.toString() : "",
    );

    categoriaSeleccionada = widget.producto != null
        ? widget.producto!.categoria
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.producto != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //🔷 TITULO
            Text(
              isEdit ? "Editar Producto" : "Crear Producto",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 🔷PRECIO
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

            //🔷 PRECIO
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Coste",
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔷 CATEGORIA
            DropdownButtonFormField<CategoriaProducto>(
              value: categoriaSeleccionada,
              decoration: InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: CategoriaProducto.values.map((cat) {
                final label = cat.toString().split('.').last;
                return DropdownMenuItem(
                  value: cat,
                  child: Text(label, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (v) => setState(() => categoriaSeleccionada = v),
            ),

            const SizedBox(height: 26),

            // 🔷 BOTONES
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
                          content: Text("Todos los campos son obligatorios"),
                        ),
                      );
                      return;
                    }

                    final producto = Producto(
                      id:
                          widget.producto?.id ??
                          DateTime.now().millisecondsSinceEpoch,
                      descripcion: nombreCtrl.text,
                      precio: double.tryParse(precioCtrl.text) ?? 0,
                      categoria: categoriaSeleccionada!,
                    );

                    Navigator.pop(context, producto); // 👈 DEVUELVE EL PRODUCTO
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
