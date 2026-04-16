import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:expositor_app/data/services/pedido_service.dart';
import 'package:expositor_app/presentation/pages/admin/pedido_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ClienteDetailsPage extends StatefulWidget {
  final Cliente cliente;

  const ClienteDetailsPage({super.key, required this.cliente});

  @override
  State<ClienteDetailsPage> createState() => _ClienteDetailsPageState();
}

class _ClienteDetailsPageState extends State<ClienteDetailsPage>
    with SingleTickerProviderStateMixin {
  final VendedorService vendedorService = VendedorService();
  final ClienteService clienteService = ClienteService();
  final PedidoService pedidoService = PedidoService();
  final SecureStorageService secureStorage = SecureStorageService();

  late Future<Vendedor?> futureVendedor;
  late Cliente _cliente;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    futureVendedor = vendedorService.getById(widget.cliente.idVendedor);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREAR PEDIDO
  // ============================================================
  Future<void> _crearPedido() async {
    final nuevo = await pedidoService.addPedido(idCliente: widget.cliente.id);

    if (nuevo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Error al crear pedido")));
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            PedidoDetailPage(pedido: nuevo),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.2, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        elevation: 0,
        title: Text(
          "Cliente: ${_cliente.nombre}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: "Editar cliente",
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final updated = await _showUpdateClienteDialog(
                context,
                _cliente,
                isAdmin: Session.isAdmin,
              );
              if (updated != null) {
                setState(() {
                  _cliente = updated;
                  futureVendedor = vendedorService.getById(updated.idVendedor);
                });
              }
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info del cliente compacta
                  _buildClienteInfoCard(),
                  const SizedBox(height: 20),

                  // Pedidos con detalles mejorados
                  _buildPedidosSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearPedido,
        backgroundColor: const Color(0xFF3C75EF),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nuevo Pedido',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // CARD INFO CLIENTE (compacta sin cabecera grande)
  // ============================================================
  Widget _buildClienteInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoHeader(),
              const Divider(height: 24),
              _buildInfoGrid(isSmall: isSmall),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3C75EF), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _cliente.nombre,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid({required bool isSmall}) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildInfoChip(Icons.badge_rounded, 'CIF', _cliente.cif, isSmall),
        _buildInfoChip(
          Icons.phone_rounded,
          'Teléfono',
          _cliente.telefono.isNotEmpty ? _cliente.telefono : '—',
          isSmall,
        ),
        _buildInfoChip(
          Icons.email_rounded,
          'Correo',
          _cliente.email.isNotEmpty ? _cliente.email : '—',
          isSmall,
        ),
        FutureBuilder<Vendedor?>(
          future: futureVendedor,
          builder: (context, snapshot) {
            String vendedorText = 'Cargando...';
            if (snapshot.connectionState == ConnectionState.done) {
              vendedorText = snapshot.data != null
                  ? '${snapshot.data!.nombre} ${snapshot.data!.apellido}'
                  : 'No asignado';
            }
            return _buildInfoChip(
              Icons.person_rounded,
              'Vendedor',
              vendedorText,
              isSmall,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    bool isSmall,
  ) {
    return Container(
      width: isSmall ? double.infinity : null,
      constraints: isSmall ? null : const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: isSmall ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECCIÓN DE PEDIDOS MEJORADA
  // ============================================================
  Widget _buildPedidosSection() {
    return FutureBuilder<List<Pedido>>(
      future: pedidoService.getPedidosByClienteAdmin(_cliente.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF3C75EF)),
            ),
          );
        }

        final pedidos = snapshot.data ?? [];
        final pedidosAbiertos = pedidos.where((p) => !p.cerrado).toList();
        final pedidosCerrados = pedidos.where((p) => p.cerrado).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estadísticas
              _buildPedidosHeader(
                pedidosAbiertos.length,
                pedidosCerrados.length,
              ),
              const SizedBox(height: 20),

              if (pedidos.isEmpty)
                _buildEmptyPedidos()
              else
                _buildPedidosList(pedidos),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPedidosHeader(int abiertos, int cerrados) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Pedidos del Cliente',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBadge('Abiertos', abiertos, Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBadge('Cerrados', cerrados, Colors.green),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Pedidos del Cliente',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            _buildStatBadge('Abiertos', abiertos, Colors.orange),
            const SizedBox(width: 12),
            _buildStatBadge('Cerrados', cerrados, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPedidos() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Sin pedidos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este cliente aún no tiene pedidos registrados',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosList(List<Pedido> pedidos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 900)
          crossAxisCount = 3;
        else if (constraints.maxWidth > 550)
          crossAxisCount = 2;

        return GridView.builder(
          itemCount: pedidos.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 1.1 : 0.85,
          ),
          itemBuilder: (context, index) {
            final pedido = pedidos[index];
            return _buildPedidoCard(pedido);
          },
        );
      },
    );
  }

  // ============================================================
  // CARD DE PEDIDO MEJORADA CON TODOS LOS DETALLES
  // ============================================================
  Widget _buildPedidoCard(Pedido pedido) {
    final isCerrado = pedido.cerrado;
    final statusColor = isCerrado ? Colors.green : Colors.orange;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PedidoDetailPage(pedido: pedido),
          ),
        ).then((_) => setState(() {}));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del pedido
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCerrado
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${pedido.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        pedido.fecha,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCerrado ? 'CERRADO' : 'ABIERTO',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),

            // Detalles financieros
            Expanded(
              child: Column(
                children: [
                  // Bruto e IVA
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinanceItem(
                          'Bruto',
                          '${pedido.brutoTotal} €',
                          Icons.receipt_rounded,
                          const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFinanceItem(
                          'IVA (${pedido.iva}%)',
                          '${pedido.precioIva} €',
                          Icons.percent_rounded,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Descuento y Total
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinanceItem(
                          'Descuento',
                          '${pedido.descuento}%',
                          Icons.local_offer_rounded,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFinanceItem(
                          'Total',
                          '${pedido.total} €',
                          Icons.euro_rounded,
                          const Color(0xFF10B981),
                          isHighlighted: true,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Comentario si existe
                  if (pedido.comentario.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.comment_rounded,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pedido.comentario,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF4B5563),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? color.withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isHighlighted ? 14 : 13,
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: isHighlighted ? color : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOGO ACTUALIZAR CLIENTE
  // ============================================================
  Future<Cliente?> _showUpdateClienteDialog(
    BuildContext context,
    Cliente cliente, {
    required bool isAdmin,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nombreCtrl = TextEditingController(text: cliente.nombre);
    final cifCtrl = TextEditingController(text: cliente.cif);
    final telCtrl = TextEditingController(text: cliente.telefono);
    final emailCtrl = TextEditingController(text: cliente.email);

    List<Vendedor> vendedores = [];
    int? selectedIdVendedor = cliente.idVendedor;

    return showDialog<Cliente?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Widget buildForm({List<Vendedor>? vendedoresData}) {
              vendedores = vendedoresData ?? vendedores;

              if (isAdmin &&
                  vendedores.isNotEmpty &&
                  !vendedores.any((v) => v.id == selectedIdVendedor)) {
                selectedIdVendedor = vendedores.first.id;
              }

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: InputDecoration(
                          labelText: "Nombre",
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Requerido"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cifCtrl,
                        decoration: InputDecoration(
                          labelText: "CIF",
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Requerido"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: telCtrl,
                        decoration: InputDecoration(
                          labelText: "Teléfono",
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: "Correo",
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedIdVendedor,
                          decoration: InputDecoration(
                            labelText: "Vendedor",
                            labelStyle: GoogleFonts.poppins(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: (vendedoresData ?? vendedores)
                              .map(
                                (v) => DropdownMenuItem<int>(
                                  value: v.id,
                                  child: Text(
                                    "${v.nombre} ${v.apellido}",
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setLocalState(() => selectedIdVendedor = value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Actualizar cliente",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 420,
                child: isAdmin
                    ? FutureBuilder<List<Vendedor>>(
                        future: vendedorService.getVendedores(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final data = snapshot.data ?? [];
                          return buildForm(vendedoresData: data);
                        },
                      )
                    : buildForm(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    final actualizado = Cliente(
                      id: cliente.id,
                      nombre: nombreCtrl.text.trim(),
                      cif: cifCtrl.text.trim(),
                      telefono: telCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      idVendedor: isAdmin
                          ? (selectedIdVendedor ?? cliente.idVendedor)
                          : cliente.idVendedor,
                      idPedidos: cliente.idPedidos,
                      pedidosCerrados: cliente.pedidosCerrados,
                      pedidosAbiertos: cliente.pedidosAbiertos,
                    );

                    final ok = await clienteService.update(actualizado);
                    if (!context.mounted) return;

                    if (ok == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("❌ No se pudo actualizar el cliente"),
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Cliente actualizado")),
                    );
                    Navigator.pop(context, ok);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C75EF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Guardar",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
