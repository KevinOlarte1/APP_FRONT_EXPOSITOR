import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

const _kAccent = Color(0xFF3B82F6);

class GestionVendedoresPage extends StatefulWidget {
  const GestionVendedoresPage({super.key});

  @override
  State<GestionVendedoresPage> createState() => _GestionVendedoresPageState();
}

class _GestionVendedoresPageState extends State<GestionVendedoresPage> {
  final VendedorService _vendedorService = VendedorService();
  final TextEditingController _searchController = TextEditingController();

  List<Vendedor> _vendedores = [];
  List<Vendedor> _vendedoresFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final lista = await _vendedorService.getVendedores();
    setState(() {
      _vendedores = lista;
      _vendedoresFiltrados = lista;
      _isLoading = false;
    });
  }

  void _filtrar() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _vendedoresFiltrados = _vendedores;
      } else {
        _vendedoresFiltrados = _vendedores.where((v) {
          return v.nombre.toLowerCase().contains(query) ||
              v.apellido.toLowerCase().contains(query) ||
              v.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _mostrarDialogoCrear() => _showVendedorDialog(null);
  void _mostrarDialogoEditar(Vendedor v) => _showVendedorDialog(v);

  void _showVendedorDialog(Vendedor? vendedor) {
    final nombreCtrl = TextEditingController(text: vendedor?.nombre ?? '');
    final apellidoCtrl = TextEditingController(text: vendedor?.apellido ?? '');
    final emailCtrl = TextEditingController(text: vendedor?.email ?? '');
    final passwordCtrl = TextEditingController();
    bool obscurePass = true;
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
                  Icons.person_rounded,
                  color: _kAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                vendedor == null ? 'Nuevo Vendedor' : 'Editar Vendedor',
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
                children: [
                  _DialogField(
                    label: 'Nombre',
                    controller: nombreCtrl,
                    hint: 'Ej: Carlos',
                    icon: Icons.badge_outlined,
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    label: 'Apellido',
                    controller: apellidoCtrl,
                    hint: 'Ej: García',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    label: 'Email',
                    controller: emailCtrl,
                    hint: 'correo@ejemplo.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendedor == null ? 'Contraseña' : 'Nueva contraseña',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePass,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: vendedor == null
                              ? 'Contraseña de acceso'
                              : 'Dejar vacío para no cambiar',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                              () => obscurePass = !obscurePass,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _kAccent),
                          ),
                        ),
                      ),
                    ],
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
                            final nombre = nombreCtrl.text.trim();
                            final apellido = apellidoCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final password = passwordCtrl.text.trim();

                            if (nombre.isEmpty ||
                                apellido.isEmpty ||
                                email.isEmpty) {
                              _snack(
                                'Nombre, apellido y email son obligatorios',
                                isError: true,
                              );
                              return;
                            }
                            if (vendedor == null && password.isEmpty) {
                              _snack(
                                'La contraseña es obligatoria para crear un vendedor',
                                isError: true,
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            Navigator.pop(context);

                            bool ok;
                            if (vendedor == null) {
                              final nuevo = await _vendedorService
                                  .createVendedor(
                                    nombre: nombre,
                                    apellido: apellido,
                                    email: email,
                                    password: password,
                                  );
                              ok = nuevo != null;
                            } else {
                              ok = await _vendedorService.updateById(
                                vendedor.id,
                                nombre: nombre,
                                apellido: apellido,
                                email: email,
                                password: password.isEmpty ? null : password,
                              );
                            }

                            _snack(
                              ok
                                  ? (vendedor == null
                                        ? 'Vendedor creado correctamente'
                                        : 'Vendedor actualizado correctamente')
                                  : (vendedor == null
                                        ? 'Error al crear el vendedor'
                                        : 'Error al actualizar el vendedor'),
                              isError: !ok,
                            );
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
                            vendedor == null ? 'Crear' : 'Guardar',
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

  void _confirmarEliminar(Vendedor vendedor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar Vendedor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          '¿Estas seguro de que deseas eliminar a "${vendedor.nombre} ${vendedor.apellido}"?\n\nEsta accion eliminara todos sus datos.',
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
              final ok = await _vendedorService.deleteVendedor(vendedor.id);
              _snack(
                ok
                    ? 'Vendedor eliminado correctamente'
                    : 'Error al eliminar el vendedor',
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

  void _snack(String message, {bool isError = false}) {
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
          'Gestion de Vendedores',
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
                  total: _vendedores.length,
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
                          hintText: 'Buscar por nombre, apellido o email...',
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
                        '${_vendedoresFiltrados.length} vendedores encontrados',
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
                      else if (_vendedoresFiltrados.isEmpty)
                        _EmptyState(
                          isSearching: _searchController.text.isNotEmpty,
                          onCrear: _mostrarDialogoCrear,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vendedoresFiltrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final v = _vendedoresFiltrados[index];
                            return _VendedorItem(
                              vendedor: v,
                              onEditar: () => _mostrarDialogoEditar(v),
                              onEliminar: () => _confirmarEliminar(v),
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
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.groups_rounded,
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
                      'Vendedores',
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
                  'Doble clic en un vendedor para editarlo.',
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

// ============== VENDEDOR ITEM ==============

class _VendedorItem extends StatefulWidget {
  final Vendedor vendedor;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _VendedorItem({
    required this.vendedor,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_VendedorItem> createState() => _VendedorItemState();
}

class _VendedorItemState extends State<_VendedorItem> {
  bool _isHovered = false;

  bool get _isAdmin => widget.vendedor.role.toUpperCase().contains('ADMIN');

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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.vendedor.nombre.isNotEmpty
                      ? widget.vendedor.nombre[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
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
                    Row(
                      children: [
                        Text(
                          '${widget.vendedor.nombre} ${widget.vendedor.apellido}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _isAdmin
                                ? const Color(0xFFDC2626).withOpacity(0.1)
                                : _kAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isAdmin ? 'ADMIN' : 'USER',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isAdmin
                                  ? const Color(0xFFDC2626)
                                  : _kAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.vendedor.email,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
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
              isSearching ? Icons.search_off_rounded : Icons.groups_outlined,
              size: 40,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'Sin resultados' : 'No hay vendedores',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron vendedores con esa busqueda.'
                : 'Crea tu primer vendedor para comenzar.',
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
                'Crear vendedor',
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
