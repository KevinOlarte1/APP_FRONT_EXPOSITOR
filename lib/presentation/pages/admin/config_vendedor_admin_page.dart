import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/models/categoria.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/data/services/categoria_service.dart';

class ConfigVendedorPage extends StatefulWidget {
  final Vendedor vendedorActual;

  const ConfigVendedorPage({super.key, required this.vendedorActual});

  @override
  State<ConfigVendedorPage> createState() => _ConfigVendedorPageState();
}

class _ConfigVendedorPageState extends State<ConfigVendedorPage> {
  final VendedorService vendedorService = VendedorService();
  final CategoriaService categoriaService = CategoriaService();

  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController emailCtrl;
  final TextEditingController passwordCtrl = TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController();
    apellidoCtrl = TextEditingController();
    emailCtrl = TextEditingController();
  }

  // ===============================================================
  // INPUT FIELD
  // ===============================================================
  Widget _input({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ===============================================================
  // SAVE VENDEDOR
  // ===============================================================
  Future<void> _save() async {
    setState(() => isSaving = true);

    final updated = Vendedor(
      id: widget.vendedorActual.id,
      nombre: nombreCtrl.text.isEmpty
          ? widget.vendedorActual.nombre
          : nombreCtrl.text,
      apellido: apellidoCtrl.text.isEmpty
          ? widget.vendedorActual.apellido
          : apellidoCtrl.text,
      email: emailCtrl.text.isEmpty
          ? widget.vendedorActual.email
          : emailCtrl.text,
      role: widget.vendedorActual.role,
    );

    final success = await vendedorService.updateVendedor(
      updated,
      password: passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
    );

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Cambios guardados correctamente" : "Error al actualizar",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ===============================================================
  // CARD WRAPPER
  // ===============================================================
  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ===============================================================
  // CATEGORY CARD
  // ===============================================================
  Widget _buildCategoryCard(Categoria categoria) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.category, size: 36, color: Colors.blue.shade600),
          Text(
            categoria.nombre,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  _showEditCategoriaDialog(context, categoria);
                  // TODO un dialog con el nombre actual y luego un boton guardar , que llamara a la api si el nombre es diferente al acutal
                },
                child: const Icon(Icons.edit, size: 20, color: Colors.green),
              ),
              InkWell(
                onTap: () {
                  // TODO eliminar
                },
                child: const Icon(Icons.delete, size: 20, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // ADD CARD
  // ===============================================================
  Widget _buildAddCard() {
    return InkWell(
      onTap: () {
        _showAddCategoriaDialog();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.add, size: 44, color: Colors.blue.shade600),
        ),
      ),
    );
  }

  // ===============================================================
  // BUILD UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    final v = widget.vendedorActual;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------
            // CARD 1 — DATOS DEL VENDEDOR
            // ---------------------------------------------------
            _card(
              title: "Datos del vendedor",
              child: Column(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(v.urlAvatar),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _input(
                    label: "Nombre",
                    placeholder: v.nombre,
                    controller: nombreCtrl,
                  ),
                  _input(
                    label: "Apellido",
                    placeholder: v.apellido,
                    controller: apellidoCtrl,
                  ),
                  _input(
                    label: "Correo",
                    placeholder: v.email,
                    controller: emailCtrl,
                  ),
                  _input(
                    label: "Nueva contraseña",
                    placeholder: "******** (opcional)",
                    controller: passwordCtrl,
                    obscure: true,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C75EF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Guardar cambios",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------
            // CARD 2 — ADMINISTRAR CATEGORÍAS
            // ---------------------------------------------------
            _card(
              title: "Administrar categorías",
              child: FutureBuilder<List<Categoria>>(
                future: categoriaService.getCategorias(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categorias = snapshot.data!;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categorias.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                    itemBuilder: (context, index) {
                      if (index == categorias.length) {
                        return _buildAddCard();
                      }
                      return _buildCategoryCard(categorias[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoriaDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nueva categoría"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Nombre de la categoría",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = controller.text.trim();
                if (nombre.isEmpty) return;

                final nueva = await categoriaService.addCategoria(nombre);

                if (nueva != null) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Categoría creada")),
                  );

                  // Recargar UI
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al crear categoría")),
                  );
                }
              },
              child: const Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoriaDialog(BuildContext context, Categoria categoria) {
    final TextEditingController controller = TextEditingController(
      text: categoria.nombre,
    );
    print("Entra en dialogo");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar categoría"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Nombre de la categoría",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoNombre = controller.text.trim();

                // Si el nombre no cambia, no llamamos a la API
                if (nuevoNombre == categoria.nombre) {
                  Navigator.pop(context);
                  return;
                }

                // Llamada al backend
                final Categoria? actualizado = await categoriaService
                    .updateCategoria(categoria.id, nuevoNombre);

                if (actualizado != null) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Categoría actualizada")),
                  );

                  // 🔥 Aquí actualizas la UI
                  setState(() {
                    categoria.nombre = actualizado.nombre;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al actualizar")),
                  );
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }
}
