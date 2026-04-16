import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/categoria.dart';
import 'package:expositor_app/data/services/categoria_service.dart';

class GestionCategoriasPage extends StatefulWidget {
  const GestionCategoriasPage({super.key});

  @override
  State<GestionCategoriasPage> createState() => _GestionCategoriasPageState();
}

class _GestionCategoriasPageState extends State<GestionCategoriasPage> {
  final CategoriaService _categoriaService = CategoriaService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Categoria> _categoriasFiltradas = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _searchController.addListener(_filtrarCategorias);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    final categorias = await _categoriaService.getCategorias();
    setState(() {
      _categorias = categorias;
      _categoriasFiltradas = categorias;
      _isLoading = false;
    });
  }

  void _filtrarCategorias() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _categoriasFiltradas = _categorias;
      } else {
        _categoriasFiltradas = _categorias
            .where((c) => c.nombre.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _mostrarDialogoCrear() {
    _nombreController.clear();
    showDialog(
      context: context,
      builder: (context) => _CategoriaDialog(
        title: 'Nueva Categoria',
        controller: _nombreController,
        isLoading: _isSaving,
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          final nombre = _nombreController.text.trim();
          if (nombre.isEmpty) {
            _mostrarSnackBar('El nombre no puede estar vacio', isError: true);
            return;
          }
          setState(() => _isSaving = true);
          Navigator.pop(context);

          final nueva = await _categoriaService.addCategoria(nombre);
          setState(() => _isSaving = false);

          if (nueva != null) {
            _cargarCategorias();
            _mostrarSnackBar('Categoria creada correctamente');
          } else {
            _mostrarSnackBar('Error al crear la categoria', isError: true);
          }
        },
        confirmLabel: 'Crear',
      ),
    );
  }

  void _mostrarDialogoEditar(Categoria categoria) {
    _nombreController.text = categoria.nombre;
    showDialog(
      context: context,
      builder: (context) => _CategoriaDialog(
        title: 'Editar Categoria',
        controller: _nombreController,
        isLoading: _isSaving,
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          final nuevoNombre = _nombreController.text.trim();
          if (nuevoNombre.isEmpty) {
            _mostrarSnackBar('El nombre no puede estar vacio', isError: true);
            return;
          }
          setState(() => _isSaving = true);
          Navigator.pop(context);

          final actualizada = await _categoriaService.updateCategoria(
            categoria.id,
            nuevoNombre,
          );
          setState(() => _isSaving = false);

          if (actualizada != null) {
            _cargarCategorias();
            _mostrarSnackBar('Categoria actualizada correctamente');
          } else {
            _mostrarSnackBar('Error al actualizar la categoria', isError: true);
          }
        },
        confirmLabel: 'Guardar',
      ),
    );
  }

  void _mostrarDialogoEliminar(Categoria categoria) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar Categoria',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          '¿Estas seguro de que deseas eliminar "${categoria.nombre}"?\n\nEsta accion no se puede deshacer.',
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
              // TODO: Implementar deleteCategoria en CategoriaService
              // final eliminada = await _categoriaService.deleteCategoria(categoria.id);
              // if (eliminada) {
              //   _cargarCategorias();
              //   _mostrarSnackBar('Categoria eliminada correctamente');
              // }
              _mostrarSnackBar(
                'Funcion de eliminar no implementada',
                isError: true,
              );
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
          'Gestion de Categorias',
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
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Header Card
                _HeaderCard(
                  totalCategorias: _categorias.length,
                  onCrear: _mostrarDialogoCrear,
                ),
                const SizedBox(height: 20),

                // Search and List Card
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
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar categorias...',
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
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Results count
                      Text(
                        '${_categoriasFiltradas.length} categorias encontradas',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_categoriasFiltradas.isEmpty)
                        _EmptyState(
                          isSearching: _searchController.text.isNotEmpty,
                          onCrear: _mostrarDialogoCrear,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _categoriasFiltradas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final categoria = _categoriasFiltradas[index];
                            return _CategoriaItem(
                              categoria: categoria,
                              onEditar: () => _mostrarDialogoEditar(categoria),
                              onEliminar: () =>
                                  _mostrarDialogoEliminar(categoria),
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
  final int totalCategorias;
  final VoidCallback onCrear;

  const _HeaderCard({required this.totalCategorias, required this.onCrear});

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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.category_rounded,
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
                      'Categorias',
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
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$totalCategorias',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Organiza y gestiona las categorias de tus productos.',
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
              'Nueva',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
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

// ============== CATEGORIA ITEM ==============

class _CategoriaItem extends StatefulWidget {
  final Categoria categoria;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _CategoriaItem({
    required this.categoria,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_CategoriaItem> createState() => _CategoriaItemState();
}

class _CategoriaItemState extends State<_CategoriaItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered
              ? const Color(0xFF10B981).withOpacity(0.04)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF10B981).withOpacity(0.3)
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
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.categoria.nombre.isNotEmpty
                    ? widget.categoria.nombre[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.categoria.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${widget.categoria.id}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
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
              isSearching ? Icons.search_off_rounded : Icons.category_outlined,
              size: 40,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'Sin resultados' : 'No hay categorias',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron categorias con ese nombre.'
                : 'Crea tu primera categoria para organizar tus productos.',
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
                'Crear categoria',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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

// ============== DIALOG ==============

class _CategoriaDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;

  const _CategoriaDialog({
    required this.title,
    required this.controller,
    required this.isLoading,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.category_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre de la categoria',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Ej: Electronica, Ropa, Hogar...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
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
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
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
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        confirmLabel,
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
    );
  }
}
