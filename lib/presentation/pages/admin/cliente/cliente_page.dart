import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

import 'package:expositor_app/presentation/pages/admin/cliente/cliente_details_page.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:expositor_app/core/session/session.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 400),
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

    final lClientes = await _clienteService.getAllClientes();

    if (_isAdmin) {
      final lVendedores = await _vendedorService.getVendedores();
      setState(() {
        allClients = lClientes;
        filteredClients = lClientes;
        vendedores = lVendedores;
        _isLoading = false;
      });
    } else {
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

    List<Cliente> baseList;

    if (_isAdmin && selectedVendedor != null) {
      baseList = allClients
          .where((c) => c.idVendedor == selectedVendedor!.id)
          .toList();
    } else {
      baseList = List.of(allClients);
    }

    if (q.isEmpty) {
      setState(() => filteredClients = baseList);
      return;
    }

    setState(() {
      filteredClients = baseList.where((c) {
        final nombre = c.nombre.toLowerCase();
        final cif = c.cif.toLowerCase();
        final email = c.email.toLowerCase();
        return nombre.contains(q) || cif.contains(q) || email.contains(q);
      }).toList();
    });
  }

  void _filterByVendedor(Vendedor? vendedor) {
    setState(() => selectedVendedor = vendedor);
    _applyFilters();
  }

  void _filterBySearch(String q) {
    _applyFilters();
  }

  String _getNombreVendedor(int? idVendedor) {
    if (idVendedor == null) return 'Sin asignar';
    final vendedor = vendedores.firstWhere(
      (v) => v.id == idVendedor,
      orElse: () => Vendedor(
        id: 0,
        nombre: 'Desconocido',
        apellido: '',
        email: '',
        role: '',
      ),
    );
    return '${vendedor.nombre} ${vendedor.apellido}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  // ============== LOADING STATE ==============
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: double.infinity, height: 120),
              const SizedBox(height: 20),
              _buildShimmerBox(width: double.infinity, height: 70),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 900) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 2;
                  }
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: List.generate(
                      6,
                      (_) => SizedBox(
                        width:
                            (constraints.maxWidth - 16 * (crossAxisCount - 1)) /
                            crossAxisCount,
                        child: _buildShimmerBox(height: 180),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double? width, double height = 16}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0).withOpacity(value * 0.5 + 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // ============== MAIN CONTENT ==============
  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 20),

                // Filtros
                _buildFiltersCard(),
                const SizedBox(height: 20),

                // Grid de clientes
                _buildClientsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============== HEADER CARD ==============
  Widget _buildHeaderCard() {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildHeaderIcon(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildHeaderTitle()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        allClients.length,
                        Icons.people_rounded,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Filtrados',
                        filteredClients.length,
                        Icons.filter_list_rounded,
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRefreshButton(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCreateButton()),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              _buildHeaderIcon(),
              const SizedBox(width: 16),
              Expanded(child: _buildHeaderTitle()),
              const SizedBox(width: 20),
              _buildStatCard(
                'Total',
                allClients.length,
                Icons.people_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Filtrados',
                filteredClients.length,
                Icons.filter_list_rounded,
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 20),
              _buildRefreshButton(),
              const SizedBox(width: 12),
              _buildCreateButton(),
            ],
          );
        },
      ),
    );
  }

  // Agrega este nuevo metodo despues de _buildStatCard():
  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _loadAll,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF6B7280),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF6B7280),
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 56,
      height: 56,
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
        size: 28,
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clientes',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona y visualiza todos tus clientes',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      onPressed: _irCrearCliente,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        'Nuevo Cliente',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  // ============== FILTERS CARD ==============
  Widget _buildFiltersCard() {
    return Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 650;

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(),
                if (_isAdmin) ...[
                  const SizedBox(height: 16),
                  _buildVendedorDropdown(),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: _buildSearchField()),
              if (_isAdmin) ...[
                const SizedBox(width: 16),
                Expanded(child: _buildVendedorDropdown()),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _filterBySearch,
      style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, CIF o email...',
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  Widget _buildVendedorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Vendedor?>(
          value: selectedVendedor,
          isExpanded: true,
          hint: Text(
            'Todos los vendedores',
            style: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          items: [
            DropdownMenuItem<Vendedor?>(
              value: null,
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Todos los vendedores',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            ...vendedores.map(
              (v) => DropdownMenuItem<Vendedor?>(
                value: v,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        v.nombre.isNotEmpty ? v.nombre[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${v.nombre} ${v.apellido}',
                        style: GoogleFonts.poppins(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: _filterByVendedor,
        ),
      ),
    );
  }

  // ============== CLIENTS GRID ==============
  Widget _buildClientsGrid() {
    if (filteredClients.isEmpty &&
        _searchCtrl.text.isEmpty &&
        selectedVendedor == null) {
      return _buildEmptyState(isSearching: false);
    }

    if (filteredClients.isEmpty) {
      return _buildEmptyState(isSearching: true);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: filteredClients.length,
          itemBuilder: (context, index) {
            final cliente = filteredClients[index];
            return _ClienteCard(
              cliente: cliente,
              vendedorNombre: _getNombreVendedor(cliente.idVendedor),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClienteDetailsPage(cliente: cliente),
                  ),
                );
                await _loadAll();
                _applyFilters();
              },
            );
          },
        );
      },
    );
  }

  // ============== EMPTY STATE ==============
  Widget _buildEmptyState({required bool isSearching}) {
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
              onPressed: _irCrearCliente,
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

  // ============== CREAR CLIENTE DIALOG ==============
  void _irCrearCliente() {
    final formKey = GlobalKey<FormState>();

    final TextEditingController nombreController = TextEditingController();
    final TextEditingController cifController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    Vendedor? vendedorSeleccionado;
    String telefonoCompleto = '';
    bool isSaving = false;

    bool emailValido(String email) {
      final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      return regex.hasMatch(email);
    }

    bool cifValido(String cif) {
      final value = cif.trim().toUpperCase();
      if (value.isEmpty) return false;
      final regex = RegExp(r'^[A-Z]?[A-Z0-9]{6,15}$');
      return regex.hasMatch(value);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuevo Cliente',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Completa los datos del cliente',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
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
                        _DialogField(
                          controller: nombreController,
                          label: 'Nombre del cliente',
                          hint: 'Empresa o persona',
                          icon: Icons.business_rounded,
                          validator: (value) {
                            final nombre = value?.trim() ?? '';
                            if (nombre.isEmpty) return 'Introduce el nombre';
                            if (nombre.length < 2) return 'Nombre muy corto';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _DialogField(
                          controller: cifController,
                          label: 'CIF / NIF',
                          hint: 'B12345678',
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            final cif = value?.trim() ?? '';
                            if (cif.isEmpty) return 'Introduce el CIF';
                            if (!cifValido(cif)) return 'CIF no valido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telefono',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            IntlPhoneField(
                              initialCountryCode: 'ES',
                              disableLengthCheck: false,
                              style: GoogleFonts.poppins(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: '612345678',
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
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              onChanged: (phone) {
                                telefonoCompleto = phone.completeNumber;
                              },
                              validator: (phone) {
                                if (phone == null ||
                                    phone.number.trim().isEmpty) {
                                  return 'Introduce el telefono';
                                }
                                final soloNumero = phone.number.trim();
                                if (soloNumero.length < 7 ||
                                    soloNumero.length > 15) {
                                  return 'Numero no valido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DialogField(
                          controller: emailController,
                          label: 'Correo electronico',
                          hint: 'cliente@empresa.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Introduce el email';
                            if (!emailValido(email)) return 'Email no valido';
                            return null;
                          },
                        ),
                        if (_isAdmin) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vendedor asignado',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<Vendedor>(
                                    value: vendedorSeleccionado,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    hint: Text(
                                      'Seleccionar vendedor',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF9CA3AF),
                                        fontSize: 14,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                    ),
                                    items: vendedores.map((v) {
                                      return DropdownMenuItem<Vendedor>(
                                        value: v,
                                        child: Text(
                                          '${v.nombre} ${v.apellido}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    validator: (value) {
                                      if (_isAdmin && value == null) {
                                        return 'Selecciona un vendedor';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        vendedorSeleccionado = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
                          minimumSize: const Size.fromHeight(50),
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
                                if (!formKey.currentState!.validate()) return;

                                final nombre = nombreController.text.trim();
                                final cif = cifController.text
                                    .trim()
                                    .toUpperCase();
                                final email = emailController.text.trim();

                                if (telefonoCompleto.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Introduce un telefono valido',
                                      ),
                                      backgroundColor: const Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                  return;
                                }

                                setStateDialog(() => isSaving = true);

                                final int? idVendedor = _isAdmin
                                    ? vendedorSeleccionado!.id
                                    : Session.userId;

                                final nuevo = await _clienteService.addCliente(
                                  nombre,
                                  cif,
                                  idVendedor,
                                  telefonoCompleto,
                                  email,
                                );

                                if (nuevo == null) {
                                  setStateDialog(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Error al crear cliente',
                                        ),
                                        backgroundColor: const Color(
                                          0xFFDC2626,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                setState(() {
                                  allClients.insert(0, nuevo);
                                });
                                _applyFilters();

                                if (context.mounted) {
                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClienteDetailsPage(cliente: nuevo),
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Cliente creado correctamente',
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Crear Cliente',
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
          },
        );
      },
    );
  }
}

// ============== CLIENTE CARD ==============
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cliente.nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
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
                            fontSize: 13,
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
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
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
              const SizedBox(height: 12),
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
              fontSize: 13,
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
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.controller,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
