import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/models/categoria.dart';
import 'package:expositor_app/data/services/producto_service.dart';
import 'package:expositor_app/data/services/categoria_service.dart';

const _kAccent = Color(0xFFF59E0B);

class GestionProductosPage extends StatefulWidget {
  const GestionProductosPage({super.key});

  @override
  State<GestionProductosPage> createState() => _GestionProductosPageState();
}

class _GestionProductosPageState extends State<GestionProductosPage> {
  final ProductoService _productoService = ProductoService();
  final CategoriaService _categoriaService = CategoriaService();
  final TextEditingController _searchController = TextEditingController();

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrarProductos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _productoService.getAllProductos(),
      _categoriaService.getCategorias(),
    ]);
    setState(() {
      _productos = results[0] as List<Producto>;
      _productosFiltrados = _productos;
      _categorias = results[1] as List<Categoria>;
      _isLoading = false;
    });
  }

  void _filtrarProductos() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos.where((p) {
          return p.descripcion.toLowerCase().contains(query) ||
              (p.categoria?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  String _getNombreCategoria(int id) {
    final cat = _categorias.firstWhere(
      (c) => c.id == id,
      orElse: () => Categoria(id: 0, nombre: 'Desconocida'),
    );
    return cat.nombre;
  }

  void _mostrarDialogoCrear() => _showProductoDialog(null);
  void _mostrarDialogoEditar(Producto p) => _showProductoDialog(p);

  void _showProductoDialog(Producto? producto) {
    final descripcionCtrl = TextEditingController(
      text: producto?.descripcion ?? '',
    );
    final precioCtrl = TextEditingController(
      text: producto != null ? producto.precio.toStringAsFixed(2) : '',
    );
    int? selectedCategoriaId = producto?.categoriaId;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: _kAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                producto == null ? 'Nuevo Producto' : 'Editar Producto',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogField(
                    label: 'Descripcion',
                    controller: descripcionCtrl,
                    hint: 'Nombre o descripcion del producto',
                    icon: Icons.label_outline_rounded,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  _DialogField(
                    label: 'Precio (€)',
                    controller: precioCtrl,
                    hint: 'Ej: 9.99',
                    icon: Icons.euro_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Categoria',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: selectedCategoriaId,
                        isExpanded: true,
                        hint: Text(
                          'Seleccionar categoria',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _categorias
                            .map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(
                                  c.nombre,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedCategoriaId = value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final descripcion = descripcionCtrl.text.trim();
                            final precioText = precioCtrl.text
                                .trim()
                                .replaceAll(',', '.');
                            final precio = double.tryParse(precioText);

                            if (descripcion.isEmpty) {
                              _mostrarSnackBar(
                                'La descripcion es obligatoria',
                                isError: true,
                              );
                              return;
                            }
                            if (precio == null || precio < 0) {
                              _mostrarSnackBar(
                                'El precio no es valido',
                                isError: true,
                              );
                              return;
                            }
                            if (selectedCategoriaId == null) {
                              _mostrarSnackBar(
                                'Selecciona una categoria',
                                isError: true,
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            Navigator.pop(context);

                            final p = Producto(
                              id: producto?.id ?? 0,
                              descripcion: descripcion,
                              precio: precio,
                              categoriaId: selectedCategoriaId!,
                            );

                            bool ok;
                            if (producto == null) {
                              ok = await _productoService.createProducto(p);
                              _mostrarSnackBar(
                                ok
                                    ? 'Producto creado correctamente'
                                    : 'Error al crear el producto',
                                isError: !ok,
                              );
                            } else {
                              ok = await _productoService.updateProducto(p);
                              _mostrarSnackBar(
                                ok
                                    ? 'Producto actualizado correctamente'
                                    : 'Error al actualizar el producto',
                                isError: !ok,
                              );
                            }

                            if (ok) await _cargarDatos();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            producto == null ? 'Crear' : 'Guardar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

  void _confirmarEliminar(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar Producto',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          '¿Estas seguro de que deseas eliminar "${producto.descripcion}"?\n\nEsta accion no se puede deshacer.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await _productoService.deleteProducto(producto.id);
              _mostrarSnackBar(
                ok
                    ? 'Producto eliminado correctamente'
                    : 'Error al eliminar el producto',
                isError: !ok,
              );
              if (ok) await _cargarDatos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF374151),
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gestion de Productos',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                _HeaderCard(
                  total: _productos.length,
                  onCrear: _mostrarDialogoCrear,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por descripcion o categoria...',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _kAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${_productosFiltrados.length} productos encontrados',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_productosFiltrados.isEmpty)
                        _EmptyState(
                          isSearching: _searchController.text.isNotEmpty,
                          onCrear: _mostrarDialogoCrear,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _productosFiltrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = _productosFiltrados[index];
                            return _ProductoItem(
                              producto: p,
                              categoriaNombre: _getNombreCategoria(
                                p.categoriaId,
                              ),
                              onEditar: () => _mostrarDialogoEditar(p),
                              onEliminar: () => _confirmarEliminar(p),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============== HEADER CARD ==============

class _HeaderCard extends StatelessWidget {
  final int total;
  final VoidCallback onCrear;

  const _HeaderCard({required this.total, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Productos',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$total',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Doble clic en un producto para editarlo.',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onCrear,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Nuevo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ============== PRODUCTO ITEM ==============

class _ProductoItem extends StatefulWidget {
  final Producto producto;
  final String categoriaNombre;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ProductoItem({
    required this.producto,
    required this.categoriaNombre,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_ProductoItem> createState() => _ProductoItemState();
}

class _ProductoItemState extends State<_ProductoItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onDoubleTap: widget.onEditar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? _kAccent.withOpacity(0.04)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? _kAccent.withOpacity(0.35)
                  : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.producto.descripcion.isNotEmpty
                      ? widget.producto.descripcion[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.producto.descripcion,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.categoriaNombre,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${widget.producto.id}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.producto.precio.toStringAsFixed(2)} €',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 12),
              _ActionIconButton(
                icon: Icons.edit_outlined,
                color: const Color(0xFF3B82F6),
                tooltip: 'Editar',
                onTap: widget.onEditar,
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFDC2626),
                tooltip: 'Eliminar',
                onTap: widget.onEliminar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== ACTION ICON BUTTON ==============

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.color.withOpacity(0.12)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withOpacity(0.3)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered ? widget.color : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== DIALOG FIELD ==============

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool autofocus;

  const _DialogField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kAccent),
            ),
          ),
        ),
      ],
    );
  }
}

// ============== EMPTY STATE ==============

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCrear;

  const _EmptyState({required this.isSearching, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 40,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'Sin resultados' : 'No hay productos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron productos con esa busqueda.'
                : 'Crea tu primer producto para comenzar.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Crear producto',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
