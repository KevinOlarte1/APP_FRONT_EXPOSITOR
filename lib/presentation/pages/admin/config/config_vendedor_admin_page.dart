import 'dart:io';
import 'dart:typed_data';

import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/producto_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/models/categoria.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/data/services/categoria_service.dart';

import 'package:expositor_app/presentation/pages/admin/config/config_vendedor_detail_page.dart';
import 'package:expositor_app/presentation/widget/config/admin_menu_tile.dart';
import 'package:expositor_app/presentation/pages/admin/product_admin_page.dart';
import 'package:expositor_app/core/services/file_saver.dart';
import 'package:expositor_app/data/services/parametros_globales_service.dart';
import 'package:expositor_app/utils/download/download.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ConfigVendedorPage extends StatefulWidget {
  final Vendedor vendedorActual;

  const ConfigVendedorPage({super.key, required this.vendedorActual});

  @override
  State<ConfigVendedorPage> createState() => _ConfigVendedorPageState();
}

class _ConfigVendedorPageState extends State<ConfigVendedorPage> {
  final VendedorService vendedorService = VendedorService();
  final ProductoService productoService = ProductoService();
  final ClienteService clienteService = ClienteService();
  final CategoriaService categoriaService = CategoriaService();
  final ParametrosGlobalesService paramService = ParametrosGlobalesService();

  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController emailCtrl;
  final TextEditingController passwordCtrl = TextEditingController();

  // Controllers
  late TextEditingController descuentoCtrl;
  late TextEditingController ivaCtrl;
  late TextEditingController maxGruposCtrl;

  bool loadingDefaults = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController();
    apellidoCtrl = TextEditingController();
    emailCtrl = TextEditingController();

    descuentoCtrl = TextEditingController();
    ivaCtrl = TextEditingController();
    maxGruposCtrl = TextEditingController();

    _loadPedidoDefaults();
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
    return SizedBox(
      width: 150,
      height: 130,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  categoria.nombre,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _openEditCategoria(categoria),
                  child: const Icon(Icons.edit, size: 20, color: Colors.green),
                ),
                InkWell(
                  onTap: () {},
                  child: const Icon(Icons.delete, size: 20, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // ADD CARD
  // ===============================================================
  Widget _buildAddCard() {
    return InkWell(
      onTap: _openAddCategoria,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 150,
        height: 130,
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
          child: const Center(
            child: Icon(Icons.add, size: 44, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // OPEN DIALOG CATEGORÍA
  // ===============================================================
  void _showCategoriaDialog({
    required String title,
    Categoria? categoria,
    required Function(String nombre) onSave,
  }) {
    final TextEditingController controller = TextEditingController(
      text: categoria?.nombre ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "Nombre de la categoría",
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                      onPressed: () async {
                        final nombre = controller.text.trim();
                        if (nombre.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("El nombre no puede estar vacío"),
                            ),
                          );
                          return;
                        }

                        await onSave(nombre);
                        Navigator.pop(context);
                        setState(() {});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              categoria == null
                                  ? "Categoría creada"
                                  : "Categoría actualizada",
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C75EF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        "Guardar",
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
      },
    );
  }

  void _openAddCategoria() {
    _showCategoriaDialog(
      title: "Nueva categoría",
      categoria: null,
      onSave: (nombre) async {
        await categoriaService.addCategoria(nombre);
      },
    );
  }

  void _openEditCategoria(Categoria categoria) {
    _showCategoriaDialog(
      title: "Editar categoría",
      categoria: categoria,
      onSave: (nuevoNombre) async {
        final actualizado = await categoriaService.updateCategoria(
          categoria.id,
          nuevoNombre,
        );

        if (actualizado != null) {
          categoria.nombre = actualizado.nombre;
        }
      },
    );
  }

  // ===============================================================
  // VENDEDOR CARD
  // ===============================================================
  Widget _buildVendedorCard(Vendedor vendedor) {
    return SizedBox(
      width: 150,
      height: 160,

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConfigVendedorDetailPage(vendedor: vendedor),
            ),
          ).then((updatedVendedor) {
            if (updatedVendedor != null) {
              setState(() {});
            }
          });
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
          padding: const EdgeInsets.all(12),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(vendedor.urlAvatar),
              ),

              Column(
                children: [
                  Text(
                    "${vendedor.nombre} ${vendedor.apellido}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    vendedor.email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddVendedorCard() {
    return InkWell(
      onTap: () {
        _openAddVendedorDialog();
      },
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 150,
        height: 160,
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
          child: const Center(
            child: Icon(Icons.add, size: 44, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  void _openAddVendedorDialog() {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Crear Vendedor",
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: apellidoCtrl,
                  decoration: InputDecoration(
                    labelText: "Apellido",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C75EF),
                      ),
                      onPressed: () async {
                        final res = await vendedorService.createVendedor(
                          nombre: nombreCtrl.text,
                          apellido: apellidoCtrl.text,
                          email: emailCtrl.text,
                          password: passCtrl.text,
                        );

                        Navigator.pop(context);

                        if (res != null) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Vendedor creado correctamente",
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Crear",
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
      },
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

            if (Session.isAdmin) ...[
              // ---------------------------------------------------
              // CARD 2 — VALORES POR DEFECTO PARA PEDIDOS
              // ---------------------------------------------------
              _card(
                title: "Valores por defecto para pedidos",
                child: loadingDefaults
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          _input(
                            label: "Descuento (%)",
                            placeholder: "0 - 100",
                            controller: descuentoCtrl,
                          ),

                          _input(
                            label: "IVA (%)",
                            placeholder: "0 - 100",
                            controller: ivaCtrl,
                          ),

                          _input(
                            label: "Máximo de grupos",
                            placeholder: "1 - 50",
                            controller: maxGruposCtrl,
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: 220,
                            child: ElevatedButton(
                              onPressed: _savePedidoDefaults,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3C75EF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Guardar valores",
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
              // CARD 3 — ADMINISTRAR CATEGORÍAS
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
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 150 / 130,
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

              // ---------------------------------------------------
              // CARD 4 — ADMINISTRAR VENDEDORES
              // ---------------------------------------------------
              _card(
                title: "Administrar vendedores",
                child: FutureBuilder<List<Vendedor>>(
                  future: vendedorService.getVendedores(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final vendedores = snapshot.data!;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vendedores.length + 1,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 150 / 160,
                          ),
                      itemBuilder: (context, index) {
                        if (index == vendedores.length) {
                          return _buildAddVendedorCard();
                        }
                        return _buildVendedorCard(vendedores[index]);
                      },
                    );
                  },
                ),
              ),

              // ---------------------------------------------------
              // CARD 5 — EXPORTACIÓN CSV
              // ---------------------------------------------------
              _card(
                title: "Exportación",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Descargar datos en formato CSV",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BOTÓN EXPORTAR CLIENTES
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        onPressed: _exportClientesCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C75EF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Exportar clientes (CSV)",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOTÓN EXPORTAR PRODUCTOS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        onPressed: _exportProductosCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Exportar productos (CSV)",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // BOTÓN EXPORTAR PEDIDOS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        onPressed: _exportPedidosCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange, // Nuevo color
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Exportar pedidos (CSV)",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // BOTÓN EXPORTAR CATEGORÍAS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        onPressed: _exportCategoriasCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Exportar categorías (CSV)",
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
              // CARD 6— IMPORTACIONES
              // ---------------------------------------------------
              _card(
                title: "Importaciones",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Subir archivos CSV para cargar productos o clientes al sistema.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BOTÓN — Importar productos
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        onPressed: _importProductosCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Importar productos (CSV)",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOTÓN — Importar clientes
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        onPressed: _importClientesCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Importar clientes (CSV)",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOTÓN — Importar categorías
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        onPressed: _importCategoriasCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          "Importar categorías (CSV)",
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
              // CARD 7 — ADMINISTRAR PRODUCTOS (MODULARIZADO)
              // ---------------------------------------------------
              AdminMenuTile(
                title: "Administrar Productos",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductAdminPage()),
                  );
                },
              ),
              AdminMenuTile(
                title: "Borrar datos de categorias/producto/cliente",
                onTap: () {
                  deleteDatos();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportClientesCsv() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Descargando clientes...")));

    final data = await clienteService.getClientesCsv();

    if (data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al descargar CSV")));
      return;
    }

    // Guardar archivo en el dispositivo
    await _saveFile(data, "clientes.csv");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Clientes exportados correctamente.")),
    );
  }

  Future<void> _exportCategoriasCsv() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Descargando categorías...")));

    final data = await categoriaService.getCategoriasCsv();

    if (data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al descargar CSV")));
      return;
    }

    await _saveFile(data, "categorias.csv");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Categorías exportadas correctamente.")),
    );
  }

  Future<void> _exportPedidosCsv() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Descargando pedidos...")));

    final data = await productoService
        .getPedidosCsv(); // <-- AÚN lo creamos abajo

    if (data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al descargar CSV")));
      return;
    }

    await _saveFile(data, "pedidos.csv");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pedidos exportados correctamente.")),
    );
  }

  Future<void> _exportProductosCsv() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Descargando productos...")));

    final data = await productoService.getProductosCsv();

    if (data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al descargar CSV")));
      return;
    }

    await _saveFile(data, "productos.csv");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Productos exportados correctamente.")),
    );
  }

  Future<void> _importCategoriasCsv() async {
    Uint8List? bytes;
    String? filename;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null) return;

    bytes = result.files.first.bytes!;
    filename = result.files.first.name;

    final ok = await categoriaService.importarCategoriasCsv(bytes, filename);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Categorías importadas correctamente"
              : "Error al importar categorías",
        ),
      ),
    );

    if (ok) {
      setState(() {}); // refresca la grid de categorías
    }
  }

  Future<void> _loadPedidoDefaults() async {
    try {
      final cfg = await paramService.getParams();

      print("CONFIG RECIBIDA: $cfg"); // 👈 DEBUG

      descuentoCtrl.text = cfg["descuento"].toString();
      ivaCtrl.text = cfg["iva"].toString();
      maxGruposCtrl.text = cfg["grupoMax"].toString();
    } catch (e) {
      print("❌ Error cargando parámetros globales: $e"); // 👈 VER ERROR REAL

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error cargando parámetros globales.")),
      );
    }

    setState(() => loadingDefaults = false);
  }

  Future<void> _savePedidoDefaults() async {
    final d = double.tryParse(descuentoCtrl.text) ?? -1;
    final i = double.tryParse(ivaCtrl.text) ?? -1;
    final g = int.tryParse(maxGruposCtrl.text) ?? -1;

    if (d < 0 || d > 100 || i < 0 || i > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("IVA y descuento deben estar entre 0 y 100."),
        ),
      );
      return;
    }

    if (g <= 0 || g > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El máximo de grupos debe estar entre 1 y 50."),
        ),
      );
      return;
    }

    final ok = await paramService.saveParams(iva: i, descuento: d, grupoMax: g);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error guardando en el servidor.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Valores guardados correctamente.")),
    );
  }

  Future<void> _saveFile(Uint8List bytes, String filename) async {
    await downloadBytes(bytes, filename);
  }

  Future<void> _importProductosCsv() async {
    Uint8List? bytes;
    String? filename;

    if (kIsWeb) {
      // Usa el archivo web que ya tienes creado (más seguro)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null) return;

      bytes = result.files.first.bytes;
      filename = result.files.first.name;
    } else {
      // ANDROID / iOS
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null) return;

      bytes = result.files.first.bytes!;
      filename = result.files.first.name;
    }

    final ok = await productoService.importarProductosCsv(bytes!, filename!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Productos importados correctamente"
              : "Error al importar productos",
        ),
      ),
    );
  }

  Future<void> _importClientesCsv() async {
    Uint8List? bytes;
    String? filename;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null) return;

    bytes = result.files.first.bytes!;
    filename = result.files.first.name;

    final ok = await clienteService.importarClientesCsv(bytes, filename);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Clientes importados correctamente"
              : "Error al importar clientes",
        ),
      ),
    );
  }

  Future<void> deleteDatos() async {
    final ok = await clienteService.deleteDatos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Datos borrados correctamente" : "Error al borrar datos",
        ),
      ),
    );
  }
}
