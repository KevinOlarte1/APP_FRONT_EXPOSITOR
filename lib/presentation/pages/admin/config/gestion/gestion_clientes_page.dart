import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

class GestionClientesPage extends StatefulWidget {
  const GestionClientesPage({super.key});

  @override
  State<GestionClientesPage> createState() => _GestionClientesPageState();
}

class _GestionClientesPageState extends State<GestionClientesPage> {
  final ClienteService _clienteService = ClienteService();
  final VendedorService _vendedorService = VendedorService();
  final TextEditingController _searchController = TextEditingController();

  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  List<Vendedor> _vendedores = [];
  bool _isLoading = true;
  bool _hayCambios = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _clienteService.getAllClientes(),
      _vendedorService.getVendedores(),
    ]);
    setState(() {
      _clientes = results[0] as List<Cliente>;
      _clientesFiltrados = _clientes;
      _vendedores = results[1] as List<Vendedor>;
      _isLoading = false;
    });
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _clientesFiltrados = _clientes;
      } else {
        _clientesFiltrados = _clientes.where((c) {
          return c.nombre.toLowerCase().contains(query) ||
              c.cif.toLowerCase().contains(query) ||
              c.email.toLowerCase().contains(query) ||
              (c.telefono?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  String _getNombreVendedor(int? idVendedor) {
    if (idVendedor == null) return 'Sin asignar';
    final vendedor = _vendedores.firstWhere(
      (v) => v.id == idVendedor,
      orElse: () => Vendedor(
        id: 0,
        nombre: 'Desconocido',
        apellido: '',
        email: '',
        role: 'desc',
      ),
    );
    return '${vendedor.nombre} ${vendedor.apellido}'.trim();
  }

  void _mostrarDialogoCrear() {
    _showClienteDialog(null);
  }

  void _mostrarDialogoEditar(Cliente cliente) {
    _showClienteDialog(cliente);
  }

  void _showClienteDialog(Cliente? cliente) {
    final nombreController = TextEditingController(text: cliente?.nombre ?? '');
    final cifController = TextEditingController(text: cliente?.cif ?? '');
    final telefonoController = TextEditingController(
      text: cliente?.telefono ?? '',
    );
    final emailController = TextEditingController(text: cliente?.email ?? '');
    int? selectedVendedorId = cliente?.idVendedor;
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
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogField(
                    label: 'Nombre',
                    controller: nombreController,
                    hint: 'Nombre del cliente o empresa',
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DialogField(
                    label: 'CIF / NIF',
                    controller: cifController,
                    hint: 'Ej: B12345678',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _DialogField(
                    label: 'Telefono',
                    controller: telefonoController,
                    hint: 'Ej: 612345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _DialogField(
                    label: 'Email',
                    controller: emailController,
                    hint: 'correo@ejemplo.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vendedor Asignado',
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
                        value: selectedVendedorId,
                        isExpanded: true,
                        hint: Text(
                          'Seleccionar vendedor',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Sin asignar',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          ..._vendedores.map(
                            (v) => DropdownMenuItem<int?>(
                              value: v.id,
                              child: Text(
                                '${v.nombre} ${v.apellido}',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedVendedorId = value);
                        },
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
                    onPressed: () => Navigator.pop(context, _hayCambios),
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
                            final nombre = nombreController.text.trim();
                            final cif = cifController.text.trim();
                            final telefono = telefonoController.text.trim();
                            final email = emailController.text.trim();

                            if (nombre.isEmpty || cif.isEmpty) {
                              _mostrarSnackBar(
                                'Nombre y CIF son obligatorios',
                                isError: true,
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            Navigator.pop(context);

                            if (cliente == null) {
                              // Crear nuevo
                              final nuevo = await _clienteService.addCliente(
                                nombre,
                                cif,
                                selectedVendedorId,
                                telefono,
                                email,
                              );
                              if (nuevo != null) {
                                _hayCambios = true;
                                await _cargarDatos();
                                _mostrarSnackBar(
                                  'Cliente creado correctamente',
                                );
                              } else {
                                _mostrarSnackBar(
                                  'Error al crear el cliente',
                                  isError: true,
                                );
                              }
                            } else {
                              // Actualizar
                              final actualizado = Cliente(
                                id: cliente.id,
                                nombre: nombre,
                                cif: cif,
                                telefono: telefono,
                                email: email,
                                idVendedor:
                                    selectedVendedorId ?? cliente.idVendedor,
                                idPedidos: cliente.idPedidos,
                                pedidosAbiertos: cliente.pedidosAbiertos,
                                pedidosCerrados: cliente.pedidosCerrados,
                              );
                              final result = await _clienteService.update(
                                actualizado,
                              );
                              if (result != null) {
                                _hayCambios = true;
                                await _cargarDatos();
                                _mostrarSnackBar(
                                  'Cliente actualizado correctamente',
                                );
                              } else {
                                _mostrarSnackBar(
                                  'Error al actualizar el cliente',
                                  isError: true,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
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
                            cliente == null ? 'Crear' : 'Guardar',
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
          'Gestion de Clientes',
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
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                // Header Card
                _HeaderCard(
                  totalClientes: _clientes.length,
                  onCrear: _mostrarDialogoCrear,
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
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
                          hintText:
                              'Buscar por nombre, CIF, email o telefono...',
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
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_clientesFiltrados.length} clientes encontrados',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Grid de tarjetas
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_clientesFiltrados.isEmpty)
                  _EmptyState(
                    isSearching: _searchController.text.isNotEmpty,
                    onCrear: _mostrarDialogoCrear,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 800) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 500) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.35,
                        ),
                        itemCount: _clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = _clientesFiltrados[index];
                          return _ClienteCard(
                            cliente: cliente,
                            vendedorNombre: _getNombreVendedor(
                              cliente.idVendedor,
                            ),
                            onDoubleTap: () => _mostrarDialogoEditar(cliente),
                          );
                        },
                      );
                    },
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
  final int totalClientes;
  final VoidCallback onCrear;

  const _HeaderCard({required this.totalClientes, required this.onCrear});

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
              Icons.people_alt_rounded,
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
                      'Clientes',
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
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$totalClientes',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Doble clic en una tarjeta para editar el cliente.',
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
              backgroundColor: const Color(0xFF3B82F6),
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

// ============== CLIENTE CARD ==============

class _ClienteCard extends StatefulWidget {
  final Cliente cliente;
  final String vendedorNombre;
  final VoidCallback onDoubleTap;

  const _ClienteCard({
    required this.cliente,
    required this.vendedorNombre,
    required this.onDoubleTap,
  });

  @override
  State<_ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends State<_ClienteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF3B82F6).withOpacity(0.4)
                  : const Color(0xFFE8EDF3),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFF3B82F6).withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.cliente.nombre.isNotEmpty
                          ? widget.cliente.nombre[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cliente.nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.cliente.cif,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isHovered)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              _InfoRow(
                icon: Icons.email_outlined,
                value: widget.cliente.email.isNotEmpty
                    ? widget.cliente.email
                    : 'Sin email',
                isPlaceholder: widget.cliente.email.isEmpty,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.phone_outlined,
                value: widget.cliente.telefono?.isNotEmpty == true
                    ? widget.cliente.telefono!
                    : 'Sin telefono',
                isPlaceholder: widget.cliente.telefono?.isEmpty ?? true,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.cliente.idVendedor != null
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: widget.cliente.idVendedor != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.vendedorNombre,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.cliente.idVendedor != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== INFO ROW ==============

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isPlaceholder;

  const _InfoRow({
    required this.icon,
    required this.value,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isPlaceholder
              ? const Color(0xFFD1D5DB)
              : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: isPlaceholder
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF6B7280),
              fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  const _DialogField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
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
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
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
                  : Icons.people_outline_rounded,
              size: 40,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'Sin resultados' : 'No hay clientes',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron clientes con esa busqueda.'
                : 'Crea tu primer cliente para comenzar.',
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
                'Crear cliente',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
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
