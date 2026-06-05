import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

import 'package:expositor_app/presentation/pages/admin/cliente/cliente_details_page.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:expositor_app/core/session/session.dart';

// ─────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────
const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE2E8F0);
const _primary = Color(0xFF2563EB);
const _primaryLight = Color(0xFFEFF6FF);
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _textTertiary = Color(0xFF94A3B8);
const _success = Color(0xFF22C55E);
const _successLight = Color(0xFFF0FDF4);
const _error = Color(0xFFEF4444);

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => ClientesPageState();
}

class ClientesPageState extends State<ClientesPage>
    with SingleTickerProviderStateMixin {
  void refresh() => _loadAll();

  final ClienteService _clienteService = ClienteService();
  final VendedorService _vendedorService = VendedorService();
  final bool _isAdmin = Session.isAdmin;

  List<Cliente> allClients = [];
  List<Cliente> filteredClients = [];
  List<Vendedor> vendedores = [];
  Vendedor? selectedVendedor;

  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    _fadeController.reset();

    final lClientes = await _clienteService.getAllClientes();

    if (_isAdmin) {
      final lVendedores = await _vendedorService.getVendedores();
      if (!mounted) return;
      // Remap selectedVendedor a la nueva instancia de la lista (compara por id)
      final prevId = selectedVendedor?.id;
      setState(() {
        allClients = lClientes;
        filteredClients = lClientes;
        vendedores = lVendedores;
        selectedVendedor = prevId != null
            ? lVendedores.where((v) => v.id == prevId).firstOrNull
            : null;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        allClients = lClientes;
        filteredClients = lClientes;
        vendedores = [];
        selectedVendedor = null;
        _isLoading = false;
      });
    }
    _fadeController.forward();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    List<Cliente> base = _isAdmin && selectedVendedor != null
        ? allClients.where((c) => c.idVendedor == selectedVendedor!.id).toList()
        : List.of(allClients);

    if (q.isEmpty) {
      setState(() => filteredClients = base);
      return;
    }
    setState(() {
      filteredClients = base.where((c) {
        return c.nombre.toLowerCase().contains(q) ||
            c.cif.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _filterByVendedor(Vendedor? v) {
    setState(() => selectedVendedor = v);
    _applyFilters();
  }

  String _getNombreVendedor(int? idVendedor) {
    if (idVendedor == null) return 'Sin asignar';
    final v = vendedores.firstWhere(
      (v) => v.id == idVendedor,
      orElse: () => Vendedor(
        id: 0,
        nombre: 'Desconocido',
        apellido: '',
        email: '',
        role: '',
      ),
    );
    return '${v.nombre} ${v.apellido}'.trim();
  }

  void _goToCliente(Cliente c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClienteDetailsPage(cliente: c)),
    );
    await _loadAll();
    _applyFilters();
  }

  int _crossAxisCount(double w) {
    if (w > 1400) return 4;
    if (w > 960) return 3;
    if (w > 600) return 2;
    return 1;
  }

  // ─── BUILD ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: _isLoading ? _buildSkeleton() : _buildBody()),
    );
  }

  // ─── SKELETON ───────────────────────────────
  Widget _buildSkeleton() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final pad = constraints.maxWidth < 600 ? 16.0 : 28.0;
        final cols = _crossAxisCount(constraints.maxWidth);
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header skeleton
                Row(
                  children: [
                    _Sk(width: 140, height: 28),
                    const Spacer(),
                    _Sk(width: 36, height: 36, radius: 10),
                    const SizedBox(width: 10),
                    _Sk(width: 130, height: 36, radius: 10),
                  ],
                ),
                const SizedBox(height: 6),
                _Sk(width: 200, height: 16),
                const SizedBox(height: 24),
                // Search bar skeleton
                _Sk(width: double.infinity, height: 44, radius: 12),
                const SizedBox(height: 20),
                // Stats row
                Row(
                  children: [
                    _Sk(width: 80, height: 32, radius: 8),
                    const SizedBox(width: 10),
                    _Sk(width: 80, height: 32, radius: 8),
                  ],
                ),
                const SizedBox(height: 20),
                // Cards
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: List.generate(cols * 2, (_) {
                    final cardW =
                        (constraints.maxWidth - pad * 2 - 14 * (cols - 1)) /
                        cols;
                    return _Sk(width: cardW, height: cols == 1 ? 76 : 180);
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── BODY ───────────────────────────────────
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final pad = constraints.maxWidth < 600 ? 16.0 : 28.0;
          final isMobile = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(isMobile),
                    const SizedBox(height: 20),
                    _buildToolbar(isMobile),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildClientList(constraints.maxWidth - pad * 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── PAGE HEADER ────────────────────────────
  Widget _buildPageHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clientes', style: _titleStyle),
          const SizedBox(height: 4),
          Text(
            '${allClients.length} clientes registrados',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _RefreshBtn(loading: _isLoading, onTap: _loadAll),
              const SizedBox(width: 10),
              Expanded(child: _NewClientBtn(onTap: _irCrearCliente)),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clientes', style: _titleStyle),
              const SizedBox(height: 4),
              Text(
                '${allClients.length} clientes registrados',
                style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
              ),
            ],
          ),
        ),
        _RefreshBtn(loading: _isLoading, onTap: _loadAll),
        const SizedBox(width: 10),
        _NewClientBtn(onTap: _irCrearCliente),
      ],
    );
  }

  // ─── TOOLBAR ────────────────────────────────
  Widget _buildToolbar(bool isMobile) {
    final searchField = _SearchField(
      controller: _searchCtrl,
      onChanged: (_) => _applyFilters(),
    );

    if (!_isAdmin || vendedores.isEmpty) return searchField;

    if (isMobile) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 10),
          _VendedorFilter(
            vendedores: vendedores,
            selected: selectedVendedor,
            onChanged: _filterByVendedor,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _VendedorFilter(
            vendedores: vendedores,
            selected: selectedVendedor,
            onChanged: _filterByVendedor,
          ),
        ),
      ],
    );
  }

  // ─── STATS ROW ──────────────────────────────
  Widget _buildStatsRow() {
    final isFiltered = filteredClients.length != allClients.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          label: 'Total',
          value: allClients.length,
          color: _primary,
          bg: _primaryLight,
        ),
        if (isFiltered)
          _StatChip(
            label: 'Filtrados',
            value: filteredClients.length,
            color: _success,
            bg: _successLight,
          ),
        if (selectedVendedor != null)
          _FilterTag(
            label: '${selectedVendedor!.nombre} ${selectedVendedor!.apellido}',
            onRemove: () => _filterByVendedor(null),
          ),
        if (_searchCtrl.text.isNotEmpty)
          _FilterTag(
            label: '"${_searchCtrl.text}"',
            onRemove: () {
              _searchCtrl.clear();
              _applyFilters();
            },
          ),
      ],
    );
  }

  // ─── CLIENT LIST ────────────────────────────
  Widget _buildClientList(double availableWidth) {
    if (filteredClients.isEmpty) return _buildEmptyState();

    final cols = _crossAxisCount(availableWidth);

    if (cols == 1) {
      return _buildMobileList();
    }
    return _buildDesktopGrid(cols);
  }

  Widget _buildMobileList() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredClients.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _border, indent: 16, endIndent: 16),
        itemBuilder: (_, i) {
          final c = filteredClients[i];
          return _ClienteRow(
            cliente: c,
            vendedorNombre: _getNombreVendedor(c.idVendedor),
            onTap: () => _goToCliente(c),
            isFirst: i == 0,
            isLast: i == filteredClients.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildDesktopGrid(int cols) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 196,
      ),
      itemCount: filteredClients.length,
      itemBuilder: (_, i) {
        final c = filteredClients[i];
        return _ClienteCard(
          cliente: c,
          vendedorNombre: _getNombreVendedor(c.idVendedor),
          onTap: () => _goToCliente(c),
        );
      },
    );
  }

  // ─── EMPTY STATE ────────────────────────────
  Widget _buildEmptyState() {
    final isSearching = _searchCtrl.text.isNotEmpty || selectedVendedor != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 32,
                color: _primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Sin resultados' : 'Aún no hay clientes',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Prueba con otro término o limpia los filtros.'
                  : 'Crea tu primer cliente para empezar.',
              style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!isSearching)
              _NewClientBtn(onTap: _irCrearCliente)
            else
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => selectedVendedor = null);
                  _applyFilters();
                },
                child: Text(
                  'Limpiar filtros',
                  style: GoogleFonts.poppins(
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── CREAR CLIENTE DIALOG ───────────────────
  void _irCrearCliente() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final cifCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    Vendedor? vendedorSel;
    String telefonoCompleto = '';
    bool isSaving = false;

    bool emailValido(String e) =>
        RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(e);
    bool cifValido(String c) {
      final v = c.trim().toUpperCase();
      return v.isNotEmpty && RegExp(r'^[A-Z]?[A-Z0-9]{6,15}$').hasMatch(v);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo cliente',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Completa los datos del cliente',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: _textTertiary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    _Field(
                      ctrl: nombreCtrl,
                      label: 'Nombre',
                      hint: 'Empresa o persona',
                      icon: Icons.business_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Introduce el nombre';
                        if (v.trim().length < 2) return 'Nombre muy corto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      ctrl: cifCtrl,
                      label: 'CIF / NIF',
                      hint: 'B12345678',
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Introduce el CIF';
                        if (!cifValido(v)) return 'CIF no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _phoneLabel(),
                    const SizedBox(height: 6),
                    IntlPhoneField(
                      initialCountryCode: 'ES',
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _phoneDecoration(),
                      onChanged: (p) => telefonoCompleto = p.completeNumber,
                      validator: (p) {
                        if (p == null || p.number.trim().isEmpty)
                          return 'Introduce el teléfono';
                        if (p.number.trim().length < 7 ||
                            p.number.trim().length > 15)
                          return 'Número no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      ctrl: emailCtrl,
                      label: 'Email',
                      hint: 'cliente@empresa.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Introduce el email';
                        if (!emailValido(v.trim())) return 'Email no válido';
                        return null;
                      },
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(height: 14),
                      _VendedorDropdownField(
                        vendedores: vendedores,
                        value: vendedorSel,
                        onChanged: (v) => setD(() => vendedorSel = v),
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
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
                            if (!formKey.currentState!.validate()) return;
                            if (telefonoCompleto.trim().isEmpty) {
                              _showSnack(
                                ctx,
                                'Introduce un teléfono válido',
                                isError: true,
                              );
                              return;
                            }
                            setD(() => isSaving = true);

                            final idVendedor = _isAdmin
                                ? vendedorSel!.id
                                : Session.userId;
                            final nuevo = await _clienteService.addCliente(
                              nombreCtrl.text.trim(),
                              cifCtrl.text.trim().toUpperCase(),
                              idVendedor,
                              telefonoCompleto,
                              emailCtrl.text.trim(),
                            );

                            if (nuevo == null) {
                              setD(() => isSaving = false);
                              if (ctx.mounted)
                                _showSnack(
                                  ctx,
                                  'Error al crear el cliente',
                                  isError: true,
                                );
                              return;
                            }

                            setState(() => allClients.insert(0, nuevo));
                            _applyFilters();

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _showSnack(ctx, 'Cliente creado correctamente');
                              Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClienteDetailsPage(cliente: nuevo),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Crear cliente',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
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

  void _showSnack(BuildContext ctx, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? _error : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _phoneLabel() => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      'Teléfono',
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    ),
  );

  InputDecoration _phoneDecoration() => InputDecoration(
    hintText: '612 345 678',
    hintStyle: GoogleFonts.poppins(color: _textTertiary, fontSize: 14),
    filled: true,
    fillColor: _bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _error, width: 1.5),
    ),
  );
}

// ─────────────────────────────────────────────
//  TEXT STYLE
// ─────────────────────────────────────────────
final _titleStyle = GoogleFonts.poppins(
  fontSize: 26,
  fontWeight: FontWeight.w700,
  color: _textPrimary,
  height: 1.2,
);

// ─────────────────────────────────────────────
//  TOOLBAR WIDGETS
// ─────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, CIF o email…',
        hintStyle: GoogleFonts.poppins(color: _textTertiary, fontSize: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _textTertiary,
          size: 20,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _textTertiary,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

class _VendedorFilter extends StatelessWidget {
  final List<Vendedor> vendedores;
  final Vendedor? selected;
  final ValueChanged<Vendedor?> onChanged;

  const _VendedorFilter({
    required this.vendedores,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null ? _primary : _border,
          width: selected != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Vendedor?>(
          value: selected,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: _textTertiary,
            size: 20,
          ),
          hint: Text(
            'Todos los vendedores',
            style: GoogleFonts.poppins(color: _textTertiary, fontSize: 13),
          ),
          style: GoogleFonts.poppins(fontSize: 13, color: _textPrimary),
          items: [
            DropdownMenuItem<Vendedor?>(
              value: null,
              child: Text(
                'Todos los vendedores',
                style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
              ),
            ),
            ...vendedores.map(
              (v) => DropdownMenuItem<Vendedor?>(
                value: v,
                child: Text(
                  '${v.nombre} ${v.apellido}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT CHIPS & FILTER TAGS
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: _textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BUTTONS
// ─────────────────────────────────────────────
class _RefreshBtn extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;

  const _RefreshBtn({required this.loading, required this.onTap});

  @override
  State<_RefreshBtn> createState() => _RefreshBtnState();
}

class _RefreshBtnState extends State<_RefreshBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(_RefreshBtn old) {
    super.didUpdateWidget(old);
    if (widget.loading) {
      _spin.repeat();
    } else {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Actualizar',
      child: InkWell(
        onTap: widget.loading ? null : widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Center(
            child: RotationTransition(
              turns: _spin,
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: widget.loading ? _textTertiary : _textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewClientBtn extends StatelessWidget {
  final VoidCallback onTap;

  const _NewClientBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        'Nuevo cliente',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CLIENTE CARD (tablet / desktop grid)
// ─────────────────────────────────────────────
class _ClienteCard extends StatefulWidget {
  final Cliente cliente;
  final String vendedorNombre;
  final VoidCallback onTap;

  const _ClienteCard({
    required this.cliente,
    required this.vendedorNombre,
    required this.onTap,
  });

  @override
  State<_ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends State<_ClienteCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? _primary : _border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: widget.cliente.nombre),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cliente.nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.cliente.cif,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 10),
              _IconRow(
                icon: Icons.mail_outline_rounded,
                value: widget.cliente.email.isNotEmpty
                    ? widget.cliente.email
                    : '—',
                empty: widget.cliente.email.isEmpty,
              ),
              const SizedBox(height: 6),
              _IconRow(
                icon: Icons.phone_outlined,
                value: (widget.cliente.telefono?.isNotEmpty ?? false)
                    ? widget.cliente.telefono!
                    : '—',
                empty: !(widget.cliente.telefono?.isNotEmpty ?? false),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.cliente.idVendedor != null
                          ? _success
                          : _textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.vendedorNombre,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: widget.cliente.idVendedor != null
                            ? _textSecondary
                            : _textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CLIENTE ROW (mobile list)
// ─────────────────────────────────────────────
class _ClienteRow extends StatelessWidget {
  final Cliente cliente;
  final String vendedorNombre;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ClienteRow({
    required this.cliente,
    required this.vendedorNombre,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _Avatar(name: cliente.nombre, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        cliente.cif,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: _textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          vendedorNombre,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool empty;

  const _IconRow({required this.icon, required this.value, this.empty = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: empty ? _border : _textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: empty ? _textTertiary : _textSecondary,
              fontStyle: empty ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  DIALOG HELPERS
// ─────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.words,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: _textTertiary, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: _textTertiary),
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _error, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _VendedorDropdownField extends StatelessWidget {
  final List<Vendedor> vendedores;
  final Vendedor? value;
  final ValueChanged<Vendedor?> onChanged;

  const _VendedorDropdownField({
    required this.vendedores,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendedor asignado',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Vendedor>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Seleccionar vendedor',
            hintStyle: GoogleFonts.poppins(color: _textTertiary, fontSize: 14),
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _error, width: 1.5),
            ),
          ),
          icon: const Icon(
            Icons.expand_more_rounded,
            color: _textTertiary,
            size: 20,
          ),
          items: vendedores
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    '${v.nombre} ${v.apellido}',
                    style: GoogleFonts.poppins(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          validator: (v) => v == null ? 'Selecciona un vendedor' : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SKELETON BOX
// ─────────────────────────────────────────────
class _Sk extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const _Sk({this.width, required this.height, this.radius = 12});

  @override
  State<_Sk> createState() => _SkState();
}

class _SkState extends State<_Sk> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.75).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
