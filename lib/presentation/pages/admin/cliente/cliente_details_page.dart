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

// ─────────────────────────────────────────────
//  Design tokens (mismos que cliente_page)
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
const _warning = Color(0xFFF59E0B);
const _warningLight = Color(0xFFFFFBEB);
const _error = Color(0xFFEF4444);

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

  late Future<Vendedor?> _futureVendedor;
  late Future<List<Pedido>> _futurePedidos;
  late Cliente _cliente;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _futureVendedor = vendedorService.getById(_cliente.idVendedor);
    _futurePedidos = pedidoService.getPedidosByClienteAdmin(_cliente.id);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
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

  void _reloadPedidos() {
    setState(() {
      _futurePedidos = pedidoService.getPedidosByClienteAdmin(_cliente.id);
    });
  }

  Future<void> _crearPedido() async {
    final nuevo = await pedidoService.addPedido(idCliente: _cliente.id);
    if (nuevo == null) {
      if (!mounted) return;
      _showSnack('Error al crear el pedido', isError: true);
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, a, __) => PedidoDetailPage(pedido: nuevo),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? _error : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final pad = constraints.maxWidth < 600 ? 16.0 : 24.0;
              return CustomScrollView(
                slivers: [
                  _buildSliverHeader(pad),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 100),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildClienteCard(constraints.maxWidth < 600),
                              const SizedBox(height: 24),
                              _buildPedidosSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearPedido,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'Nuevo pedido',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  // ─── SLIVER HEADER ──────────────────────────
  Widget _buildSliverHeader(double pad) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              children: [
                // Back button
                InkWell(
                  onTap: () => Navigator.pop(context, true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: _textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cliente.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _cliente.cif,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Edit button
                Tooltip(
                  message: 'Editar cliente',
                  child: InkWell(
                    onTap: () async {
                      final updated = await _showUpdateDialog();
                      if (updated != null) {
                        setState(() {
                          _cliente = updated;
                          _futureVendedor = vendedorService.getById(
                            updated.idVendedor,
                          );
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── CLIENTE CARD ───────────────────────────
  Widget _buildClienteCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ClientAvatar(name: _cliente.nombre, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cliente.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<Vendedor?>(
                      future: _futureVendedor,
                      builder: (_, snap) {
                        final name = snap.data != null
                            ? '${snap.data!.nombre} ${snap.data!.apellido}'
                            : snap.connectionState == ConnectionState.done
                            ? 'Sin asignar'
                            : '…';
                        return Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: snap.data != null
                                    ? _success
                                    : _textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.badge_outlined,
                label: 'CIF',
                value: _cliente.cif,
                fullWidth: isMobile,
              ),
              _InfoPill(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: (_cliente.telefono?.isNotEmpty ?? false)
                    ? _cliente.telefono!
                    : '—',
                fullWidth: isMobile,
              ),
              _InfoPill(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: _cliente.email.isNotEmpty ? _cliente.email : '—',
                fullWidth: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PEDIDOS SECTION ────────────────────────
  Widget _buildPedidosSection() {
    return FutureBuilder<List<Pedido>>(
      future: _futurePedidos,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildPedidosSkeleton();
        }

        final pedidos = snap.data ?? [];
        final abiertos = pedidos.where((p) => !p.cerrado).length;
        final cerrados = pedidos.where((p) => p.cerrado).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text(
                  'Pedidos',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                if (abiertos > 0)
                  _Badge(
                    label: '$abiertos abiertos',
                    color: _warning,
                    bg: _warningLight,
                  ),
                if (abiertos > 0 && cerrados > 0) const SizedBox(width: 8),
                if (cerrados > 0)
                  _Badge(
                    label: '$cerrados cerrados',
                    color: _success,
                    bg: _successLight,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (pedidos.isEmpty)
              _buildEmptyPedidos()
            else
              LayoutBuilder(
                builder: (_, constraints) {
                  final cols = constraints.maxWidth > 900
                      ? 3
                      : constraints.maxWidth > 560
                      ? 2
                      : 1;

                  if (cols == 1) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pedidos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PedidoCard(
                        pedido: pedidos[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PedidoDetailPage(pedido: pedidos[i]),
                            ),
                          ).then((_) => _reloadPedidos());
                        },
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 252,
                    ),
                    itemCount: pedidos.length,
                    itemBuilder: (_, i) => _PedidoCard(
                      pedido: pedidos[i],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PedidoDetailPage(pedido: pedidos[i]),
                          ),
                        ).then((_) => _reloadPedidos());
                      },
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPedidosSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Sk(width: 100, height: 22),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Sk(width: double.infinity, height: 110),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPedidos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin pedidos',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pulsa "Nuevo pedido" para crear el primero.',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── UPDATE DIALOG ──────────────────────────
  Future<Cliente?> _showUpdateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: _cliente.nombre);
    final cifCtrl = TextEditingController(text: _cliente.cif);
    final telCtrl = TextEditingController(text: _cliente.telefono ?? '');
    final emailCtrl = TextEditingController(text: _cliente.email);
    int? selectedIdVendedor = _cliente.idVendedor;
    bool isSaving = false;

    return showDialog<Cliente?>(
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
                  Icons.edit_outlined,
                  color: _primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar cliente',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Modifica los datos del cliente',
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
                  size: 19,
                  color: _textTertiary,
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
                    _DialogField(
                      ctrl: nombreCtrl,
                      label: 'Nombre',
                      hint: 'Nombre del cliente',
                      icon: Icons.business_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    _DialogField(
                      ctrl: cifCtrl,
                      label: 'CIF / NIF',
                      hint: 'B12345678',
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    _DialogField(
                      ctrl: telCtrl,
                      label: 'Teléfono',
                      hint: '+34 612 345 678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _DialogField(
                      ctrl: emailCtrl,
                      label: 'Email',
                      hint: 'cliente@empresa.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (Session.isAdmin) ...[
                      const SizedBox(height: 14),
                      FutureBuilder<List<Vendedor>>(
                        future: vendedorService.getVendedores(),
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primary,
                                ),
                              ),
                            );
                          }
                          final vs = snap.data ?? [];
                          if (!vs.any((v) => v.id == selectedIdVendedor) &&
                              vs.isNotEmpty) {
                            selectedIdVendedor = vs.first.id;
                          }
                          return _VendedorDropdown(
                            vendedores: vs,
                            value: selectedIdVendedor,
                            onChanged: (v) =>
                                setD(() => selectedIdVendedor = v),
                          );
                        },
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
                            setD(() => isSaving = true);

                            final actualizado = Cliente(
                              id: _cliente.id,
                              nombre: nombreCtrl.text.trim(),
                              cif: cifCtrl.text.trim(),
                              telefono: telCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              idVendedor: Session.isAdmin
                                  ? (selectedIdVendedor ?? _cliente.idVendedor)
                                  : _cliente.idVendedor,
                              idPedidos: _cliente.idPedidos,
                              pedidosCerrados: _cliente.pedidosCerrados,
                              pedidosAbiertos: _cliente.pedidosAbiertos,
                            );

                            final ok = await clienteService.update(actualizado);
                            if (!ctx.mounted) return;

                            if (ok == null) {
                              setD(() => isSaving = false);
                              _showSnack(
                                'No se pudo actualizar el cliente',
                                isError: true,
                              );
                              return;
                            }

                            _showSnack('Cliente actualizado correctamente');
                            Navigator.pop(ctx, ok);
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
                            'Guardar',
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
}

// ─────────────────────────────────────────────
//  PEDIDO CARD
// ─────────────────────────────────────────────
class _PedidoCard extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _PedidoCard({required this.pedido, required this.onTap});

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final closed = widget.pedido.cerrado;
    final statusColor = closed ? _success : _warning;
    final statusBg = closed ? _successLight : _warningLight;
    final statusLabel = closed ? 'Cerrado' : 'Abierto';
    final statusIcon = closed
        ? Icons.check_circle_outline_rounded
        : Icons.pending_outlined;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? _primary : _border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${widget.pedido.id}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.pedido.fecha,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _textTertiary,
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
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 12),

              // Financial grid
              Row(
                children: [
                  Expanded(
                    child: _FinRow(
                      label: 'Bruto',
                      value: '${widget.pedido.brutoTotal} €',
                      color: _textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _FinRow(
                      label: 'IVA ${widget.pedido.iva}%',
                      value: '${widget.pedido.precioIva} €',
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _FinRow(
                      label: 'Descuento',
                      value: '${widget.pedido.descuento}%',
                      color: _warning,
                    ),
                  ),
                  Expanded(
                    child: _FinRow(
                      label: 'Total',
                      value: '${widget.pedido.total} €',
                      color: _success,
                      bold: true,
                    ),
                  ),
                ],
              ),

              // Comment
              if (widget.pedido.comentario.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        size: 13,
                        color: _textTertiary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.pedido.comentario,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
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
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _FinRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: _textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL SHARED WIDGETS
// ─────────────────────────────────────────────
class _ClientAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _ClientAvatar({required this.name, this.size = 48});

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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: fullWidth ? null : const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _textTertiary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
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
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DIALOG FIELD
// ─────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _DialogField({
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

class _VendedorDropdown extends StatelessWidget {
  final List<Vendedor> vendedores;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _VendedorDropdown({
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
          'Vendedor',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
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
          ),
          icon: const Icon(
            Icons.expand_more_rounded,
            color: _textTertiary,
            size: 20,
          ),
          items: vendedores
              .map(
                (v) => DropdownMenuItem(
                  value: v.id,
                  child: Text(
                    '${v.nombre} ${v.apellido}',
                    style: GoogleFonts.poppins(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SKELETON
// ─────────────────────────────────────────────
class _Sk extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const _Sk({this.width, required this.height, this.radius = 10});

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
