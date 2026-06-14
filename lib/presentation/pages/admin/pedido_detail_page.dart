import 'package:expositor_app/data/services/parametros_globales_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/models/linea_pedido.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/models/cliente.dart';

import 'package:expositor_app/data/services/pedido_service.dart';
import 'package:expositor_app/data/services/linea_pedido_service.dart';
import 'package:expositor_app/data/services/producto_service.dart';
import 'package:expositor_app/data/services/cliente_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
const _warning = Color(0xFFF59E0B);
const _warningLight = Color(0xFFFFFBEB);
const _error = Color(0xFFEF4444);
const _errorLight = Color(0xFFFEF2F2);

class PedidoDetailPage extends StatefulWidget {
  Pedido pedido;

  PedidoDetailPage({super.key, required this.pedido});

  @override
  State<PedidoDetailPage> createState() => _PedidoDetailPageState();
}

class _PedidoDetailPageState extends State<PedidoDetailPage> {
  final ClienteService clienteService = ClienteService();
  final PedidoService pedidoService = PedidoService();
  final LineaPedidoService lineapedidoService = LineaPedidoService();
  final ProductoService productoService = ProductoService();
  final ParametrosGlobalesService paramService = ParametrosGlobalesService();

  Cliente? cliente;
  List<LineaPedido> lineas = [];
  bool loadingLineas = true;
  int? filtroGrupo;
  List<LineaPedido> lineasFiltradas = [];
  int grupoMaxConfig = 1;

  late final TextEditingController _comentarioCtrl;
  bool _guardandoComentario = false;

  @override
  void initState() {
    super.initState();
    _comentarioCtrl = TextEditingController(text: widget.pedido.comentario);
    _loadAll();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => loadingLineas = true);
    await _loadCliente();
    await _loadLineasPedido();
    grupoMaxConfig = await paramService.getGrupoMax();
    _aplicarFiltro();
  }

  void _aplicarFiltro() {
    setState(() {
      lineasFiltradas = filtroGrupo == null
          ? List.from(lineas)
          : lineas.where((l) => l.grupo == filtroGrupo).toList();
    });
  }

  Future<void> _loadCliente() async {
    final cli = await clienteService.getClienteById(widget.pedido.idCliente);
    if (mounted) setState(() => cliente = cli);
  }

  Future<void> _loadLineasPedido() async {
    setState(() => loadingLineas = true);
    final result = await lineapedidoService.getLineasPedido(
      widget.pedido.idCliente,
      widget.pedido.id,
    );
    if (mounted)
      setState(() {
        lineas = result;
        loadingLineas = false;
      });
    _aplicarFiltro();
  }

  Future<void> _refreshPedido() async {
    final updated = await pedidoService.getPedido(
      idCliente: widget.pedido.idCliente,
      idPedido: widget.pedido.id,
    );
    if (updated != null) {
      setState(() => widget.pedido = updated);
      _comentarioCtrl.text = updated.comentario;
    }
    await _loadLineasPedido();
    await _loadCliente();
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
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, constraints) {
            final pad = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return RefreshIndicator(
              onRefresh: _refreshPedido,
              color: _primary,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(pedido, pad),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 100),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: cliente == null
                              ? _buildLoadingSkeleton()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoCard(pedido, cliente!),
                                    const SizedBox(height: 20),
                                    if (!pedido.cerrado ||
                                        pedido.comentario.isNotEmpty)
                                      _buildComentarioCard(pedido),
                                    if (!pedido.cerrado ||
                                        pedido.comentario.isNotEmpty)
                                      const SizedBox(height: 20),
                                    _buildLineasCard(pedido),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────
  Widget _buildHeader(Pedido pedido, double pad) {
    final closed = pedido.cerrado;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${pedido.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        formatFecha(pedido.fecha),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: closed ? _successLight : _warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        closed
                            ? Icons.check_circle_outline_rounded
                            : Icons.pending_outlined,
                        size: 14,
                        color: closed ? _success : _warning,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        closed ? 'Cerrado' : 'Abierto',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: closed ? _success : _warning,
                        ),
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

  // ─── INFO CARD ──────────────────────────────
  Widget _buildInfoCard(Pedido pedido, Cliente cliente) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cliente row
          Row(
            children: [
              _Avatar(name: cliente.nombre, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cliente.cif,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 16),

          // Financial grid
          LayoutBuilder(
            builder: (_, constraints) {
              final wide = constraints.maxWidth > 600;
              final items = [
                _FinItem(
                  'Bruto',
                  '${pedido.brutoTotal} €',
                  _textSecondary,
                  accentColor: _border,
                  sub: '—',
                ),
                _FinItem(
                  'Base imponible',
                  '${pedido.baseImponible} €',
                  _warning,
                  accentColor: _warning,
                  sub: '${pedido.descuento}% descuento',
                ),
                _FinItem(
                  'IVA',
                  '${pedido.precioIva} €',
                  _primary,
                  accentColor: _primary,
                  sub: '${pedido.iva}% aplicado',
                ),
                _FinItem(
                  'Total',
                  '${pedido.total} €',
                  _success,
                  accentColor: _success,
                  sub: 'Precio final',
                  bold: true,
                ),
              ];
              if (wide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        Expanded(child: _buildFinBox(items[i])),
                        if (i < items.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildFinBox(items[0])),
                        const SizedBox(width: 10),
                        Expanded(child: _buildFinBox(items[1])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildFinBox(items[2])),
                        const SizedBox(width: 10),
                        Expanded(child: _buildFinBox(items[3])),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 14),

          // Action buttons
          _buildActions(pedido, cliente),
        ],
      ),
    );
  }

  Widget _buildFinBox(_FinItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent bar
            Container(height: 3, color: item.accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: GoogleFonts.poppins(
                        fontSize: item.bold ? 17 : 15,
                        fontWeight: item.bold
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.sub ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Pedido pedido, Cliente cliente) {
    if (pedido.cerrado) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActionBtn(
            icon: Icons.lock_open_rounded,
            label: 'Reabrir',
            color: _warning,
            bg: _warningLight,
            onTap: _confirmReabrirPedido,
          ),
          _ActionBtn(
            icon: Icons.copy_outlined,
            label: 'Clonar',
            color: _primary,
            bg: _primaryLight,
            onTap: () => _clonarPedido(context),
          ),
          _ActionBtn(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            color: _success,
            bg: _successLight,
            onTap: _descargarPedidoPdf,
          ),
          if (cliente.telefono?.isNotEmpty ?? false)
            _ActionBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              bg: const Color(0xFFECFDF5),
              onTap: () => _abrirWhatsApp(cliente.telefono!),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionBtn(
          icon: Icons.percent_rounded,
          label: 'Descuento',
          color: _warning,
          bg: _warningLight,
          onTap: _showEditDescuentoDialog,
        ),
        _ActionBtn(
          icon: Icons.receipt_outlined,
          label: 'IVA',
          color: _primary,
          bg: _primaryLight,
          onTap: _showEditIvaDialog,
        ),
        _ActionBtn(
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF',
          color: _success,
          bg: _successLight,
          onTap: _descargarPedidoPdf,
        ),
        _ActionBtn(
          icon: Icons.lock_outline_rounded,
          label: 'Cerrar pedido',
          color: _error,
          bg: _errorLight,
          onTap: _confirmCerrarPedido,
        ),
      ],
    );
  }

  // ─── COMENTARIO CARD ────────────────────────
  Widget _buildComentarioCard(Pedido pedido) {
    final closed = pedido.cerrado;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: _warning,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Comentario',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            readOnly: closed,
            style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary),
            decoration: InputDecoration(
              hintText: closed ? 'Sin comentarios' : 'Escribe un comentario…',
              hintStyle: GoogleFonts.poppins(
                color: _textTertiary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: closed ? _bg : _surface,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),
          if (!closed) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _guardandoComentario ? null : _guardarComentario,
                icon: _guardandoComentario
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(
                  _guardandoComentario ? 'Guardando…' : 'Guardar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _guardarComentario() async {
    setState(() => _guardandoComentario = true);
    final result = await pedidoService.updatePedido(
      idCliente: widget.pedido.idCliente,
      idPedido: widget.pedido.id,
      comentario: _comentarioCtrl.text.trim(),
    );
    final ok = result != null;
    setState(() => _guardandoComentario = false);
    if (ok) {
      _showSnack('Comentario actualizado');
      await _refreshPedido();
    } else {
      _showSnack('Error al actualizar el comentario', isError: true);
    }
  }

  // ─── LINEAS CARD ────────────────────────────
  Widget _buildLineasCard(Pedido pedido) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  size: 16,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Líneas del pedido',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '${lineasFiltradas.length} items',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Filtro grupo
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: filtroGrupo,
                isExpanded: true,
                icon: const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: _textTertiary,
                ),
                style: GoogleFonts.poppins(fontSize: 13, color: _textPrimary),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'Todos los grupos',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  ...List.generate(
                    grupoMaxConfig,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        'Grupo ${i + 1}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => filtroGrupo = v);
                  _aplicarFiltro();
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Añadir línea
          if (!pedido.cerrado) ...[
            _AddLineaBtn(onTap: _showAddLineaDialog),
            const SizedBox(height: 14),
          ],

          // Lista
          if (loadingLineas)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              ),
            )
          else if (lineasFiltradas.isEmpty)
            _buildEmptyLineas()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lineasFiltradas.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _border),
              itemBuilder: (_, i) =>
                  _buildLineaItem(lineasFiltradas[i], pedido),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLineas() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: _textTertiary),
            const SizedBox(height: 10),
            Text(
              'Sin líneas registradas',
              style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineaItem(LineaPedido linea, Pedido pedido) {
    final sinStock = linea.stockFinal == null;
    return FutureBuilder<Producto?>(
      future: productoService.getProducto(linea.idProducto),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              ),
            ),
          );
        }

        final producto = snap.data!;
        final total = (linea.precio * linea.cantidad).toStringAsFixed(2);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sinStock && !pedido.cerrado
                  ? _warning.withOpacity(0.5)
                  : _border,
              width: sinStock && !pedido.cerrado ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Fila principal ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  producto.descripcion,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              if (linea.grupo != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Text(
                                    'G${linea.grupo}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 18,
                            runSpacing: 4,
                            children: [
                              _LineaTag('Cantidad', '${linea.cantidad}'),
                              _LineaTag(
                                'Precio',
                                '${linea.precio.toStringAsFixed(2)} €',
                              ),
                              _LineaTag('Total', '$total €', bold: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!pedido.cerrado) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Eliminar línea',
                        child: InkWell(
                          onTap: () => _confirmDeleteLinea(linea),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _errorLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: _error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Footer: stock final ─────────────────
              Container(
                decoration: BoxDecoration(
                  color: _bg,
                  border: Border(top: BorderSide(color: _border)),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(13),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      linea.stockFinal != null
                          ? Icons.check_circle_outline_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 15,
                      color: linea.stockFinal != null ? _success : _warning,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Stock final: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: linea.stockFinal?.toString() ?? 'Pendiente',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: linea.stockFinal != null
                                    ? _textPrimary
                                    : _warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!pedido.cerrado)
                      GestureDetector(
                        onTap: () => _showStockFinalDialog(context, linea),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sinStock ? _warning : _primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sinStock
                                    ? Icons.add_rounded
                                    : Icons.edit_outlined,
                                size: 13,
                                color: sinStock ? Colors.white : _primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sinStock ? 'Añadir stock' : 'Editar stock',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sinStock ? Colors.white : _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        _Sk(width: double.infinity, height: 180),
        const SizedBox(height: 16),
        _Sk(width: double.infinity, height: 120),
        const SizedBox(height: 16),
        _Sk(width: double.infinity, height: 300),
      ],
    );
  }

  // ─── DIALOGS ────────────────────────────────
  void _showAddLineaDialog() async {
    Producto? productoSeleccionado;
    final unidadesCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    int grupoSeleccionado = filtroGrupo ?? 1;
    final grupoMax = await paramService.getGrupoMax();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _StyledDialog(
          title: 'Añadir línea',
          icon: Icons.add_shopping_cart_outlined,
          onClose: () => Navigator.pop(ctx),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector producto
              GestureDetector(
                onTap: () async {
                  final sel = await _showProductoSelector();
                  if (sel != null) {
                    setD(() {
                      productoSeleccionado = sel;
                      precioCtrl.text = sel.precio.toString();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: _textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          productoSeleccionado?.descripcion ??
                              'Seleccionar producto',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: productoSeleccionado != null
                                ? _textPrimary
                                : _textTertiary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: _textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SimpleField(
                ctrl: unidadesCtrl,
                label: 'Unidades',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _SimpleField(
                ctrl: precioCtrl,
                label: 'Precio unitario (€)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: grupoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Grupo',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
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
                items: List.generate(
                  grupoMax,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      'Grupo ${i + 1}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
                onChanged: (v) => setD(() => grupoSeleccionado = v!),
              ),
            ],
          ),
          onConfirm: () async {
            if (productoSeleccionado == null ||
                unidadesCtrl.text.isEmpty ||
                precioCtrl.text.isEmpty)
              return;
            final nueva = await lineapedidoService.addLineaPedido(
              widget.pedido.idCliente,
              widget.pedido.id,
              productoSeleccionado!.id,
              int.parse(unidadesCtrl.text),
              double.parse(precioCtrl.text),
              grupoSeleccionado,
            );
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (nueva != null) await _refreshPedido();
          },
          confirmLabel: 'Añadir',
        ),
      ),
    );
  }

  Future<Producto?> _showProductoSelector() async {
    final productos = await productoService.getAllProductos();
    List<Producto> filtrados = List.from(productos);
    final searchCtrl = TextEditingController();

    return showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          builder: (_, scroll) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Seleccionar producto',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchCtrl,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o categoría…',
                    hintStyle: GoogleFonts.poppins(
                      color: _textTertiary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _textTertiary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
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
                  onChanged: (q) {
                    setD(() {
                      filtrados = productos.where((p) {
                        final query = q.toLowerCase();
                        return p.descripcion.toLowerCase().contains(query) ||
                            (p.categoria ?? '').toLowerCase().contains(query);
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scroll,
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _border),
                    itemBuilder: (_, i) {
                      final p = filtrados[i];
                      return InkWell(
                        onTap: () => Navigator.pop(ctx, p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.descripcion,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    if (p.categoria != null)
                                      Text(
                                        p.categoria!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: _textTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${p.precio.toStringAsFixed(2)} €',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditLineaDialog(LineaPedido linea) async {
    final producto = await productoService.getProducto(linea.idProducto);
    final cantidadCtrl = TextEditingController(text: linea.cantidad.toString());
    final precioCtrl = TextEditingController(
      text: linea.precio.toStringAsFixed(2),
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Editar línea',
        icon: Icons.edit_outlined,
        onClose: () => Navigator.pop(ctx),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto?.descripcion ?? '—',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _SimpleField(
              ctrl: cantidadCtrl,
              label: 'Cantidad',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _SimpleField(
              ctrl: precioCtrl,
              label: 'Precio unitario (€)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        onConfirm: () async {
          final cantidad = int.tryParse(cantidadCtrl.text);
          final precio = double.tryParse(precioCtrl.text);
          if (cantidad == null || precio == null) return;
          Navigator.pop(ctx);
          final updated = await lineapedidoService.updateLineaPedido(
            widget.pedido.idCliente,
            widget.pedido.id,
            linea.id,
            cantidad,
            precio,
          );
          if (updated != null) await _refreshPedido();
        },
        confirmLabel: 'Guardar',
      ),
    );
  }

  void _confirmDeleteLinea(LineaPedido linea) {
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Eliminar línea',
        icon: Icons.delete_outline_rounded,
        iconColor: _error,
        iconBg: _errorLight,
        onClose: () => Navigator.pop(ctx),
        content: Text(
          '¿Seguro que quieres eliminar esta línea del pedido?',
          style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
        ),
        onConfirm: () async {
          Navigator.pop(ctx);
          final ok = await lineapedidoService.deleteLineaPedido(
            widget.pedido.idCliente,
            widget.pedido.id,
            linea.id,
          );
          if (ok) {
            await _refreshPedido();
          } else {
            _showSnack('Error al eliminar la línea', isError: true);
          }
        },
        confirmLabel: 'Eliminar',
        confirmColor: _error,
      ),
    );
  }

  void _confirmReabrirPedido() {
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Reabrir pedido',
        icon: Icons.lock_open_rounded,
        iconColor: _warning,
        iconBg: _warningLight,
        onClose: () => Navigator.pop(ctx),
        content: Text(
          'Al reabrir el pedido se eliminará el stock final de todas las líneas y podrás volver a editarlo.',
          style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
        ),
        onConfirm: () async {
          Navigator.pop(ctx);
          final ok = await pedidoService.reabrirPedido(
            widget.pedido.idCliente,
            widget.pedido.id,
          );
          if (ok) {
            _showSnack('Pedido reabierto correctamente');
            await _refreshPedido();
          } else {
            _showSnack('Error al reabrir el pedido', isError: true);
          }
        },
        confirmLabel: 'Reabrir',
        confirmColor: _warning,
      ),
    );
  }

  void _showEditDescuentoDialog() {
    final ctrl = TextEditingController(
      text: widget.pedido.descuento.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Editar descuento',
        icon: Icons.percent_rounded,
        iconColor: _warning,
        iconBg: _warningLight,
        onClose: () => Navigator.pop(ctx),
        content: _SimpleField(
          ctrl: ctrl,
          label: 'Descuento (%)',
          keyboardType: TextInputType.number,
        ),
        onConfirm: () async {
          final value = int.tryParse(ctrl.text.trim());
          if (value == null || value < 0 || value > 100) {
            _showSnack('Introduce un valor entre 0 y 100', isError: true);
            return;
          }
          Navigator.pop(ctx);
          final updated = await pedidoService.updatePedido(
            idCliente: widget.pedido.idCliente,
            idPedido: widget.pedido.id,
            descuento: value,
          );
          if (updated != null) {
            _showSnack('Descuento actualizado');
            await _refreshPedido();
          } else {
            _showSnack('Error al actualizar el descuento', isError: true);
          }
        },
        confirmLabel: 'Guardar',
        confirmColor: _warning,
      ),
    );
  }

  void _showEditIvaDialog() {
    final ctrl = TextEditingController(text: widget.pedido.iva.toString());
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Editar IVA',
        icon: Icons.receipt_outlined,
        iconColor: _primary,
        iconBg: _primaryLight,
        onClose: () => Navigator.pop(ctx),
        content: _SimpleField(
          ctrl: ctrl,
          label: 'IVA (%)',
          keyboardType: TextInputType.number,
        ),
        onConfirm: () async {
          final value = int.tryParse(ctrl.text.trim());
          if (value == null || value < 0 || value > 100) {
            _showSnack('Introduce un valor entre 0 y 100', isError: true);
            return;
          }
          Navigator.pop(ctx);
          final updated = await pedidoService.updatePedido(
            idCliente: widget.pedido.idCliente,
            idPedido: widget.pedido.id,
            iva: value,
          );
          if (updated != null) {
            _showSnack('IVA actualizado');
            await _refreshPedido();
          } else {
            _showSnack('Error al actualizar el IVA', isError: true);
          }
        },
        confirmLabel: 'Guardar',
      ),
    );
  }

  void _confirmCerrarPedido() {
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Cerrar pedido',
        icon: Icons.lock_outline_rounded,
        iconColor: _error,
        iconBg: _errorLight,
        onClose: () => Navigator.pop(ctx),
        content: Text(
          '¿Seguro que quieres cerrar este pedido?\nUna vez cerrado no podrás modificar las líneas.',
          style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
        ),
        onConfirm: () async {
          Navigator.pop(ctx);
          final ok = await pedidoService.cerrarPedido(
            widget.pedido.idCliente,
            widget.pedido.id,
          );
          if (ok) {
            await _refreshPedido();
          } else {
            _showSnack('Error al cerrar el pedido', isError: true);
          }
        },
        confirmLabel: 'Cerrar pedido',
        confirmColor: _error,
      ),
    );
  }

  void _showStockFinalDialog(BuildContext context, LineaPedido linea) {
    final ctrl = TextEditingController(
      text: linea.stockFinal?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Stock final',
        icon: Icons.inventory_2_outlined,
        onClose: () => Navigator.pop(ctx),
        content: _SimpleField(
          ctrl: ctrl,
          label: 'Nuevo stock final',
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        onConfirm: () async {
          final texto = ctrl.text.trim();
          final nuevo = int.tryParse(texto);
          if (nuevo == null || nuevo < 0) {
            _showSnack('Introduce un número válido', isError: true);
            return;
          }
          Navigator.pop(ctx);
          final ok = await LineaPedidoService.actualizarStockFinal(
            idCliente: widget.pedido.idCliente,
            idPedido: widget.pedido.id,
            idLinea: linea.id,
            stockFinal: nuevo,
          );
          if (ok) {
            _showSnack('Stock actualizado');
            setState(() => linea.stockFinal = nuevo);
          } else {
            _showSnack('Error al actualizar el stock', isError: true);
          }
        },
        confirmLabel: 'Guardar',
      ),
    );
  }

  Future<void> _descargarPedidoPdf() async {
    final token = widget.pedido.token;
    if (token == null || token.isEmpty) {
      _showSnack('El pedido no tiene token público', isError: true);
      return;
    }
    final url = Uri.parse(
      'https://mi-app-deposito.cloud/pedido/download?token=$token',
    );
    //final url = Uri.parse('http://localhost:8080/pedido/download?token=$token');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('No se pudo abrir el enlace', isError: true);
    }
  }

  void _clonarPedido(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Clonar pedido',
        icon: Icons.copy_outlined,
        onClose: () => Navigator.pop(ctx),
        content: Text(
          '¿Quieres clonar este pedido con todas sus líneas?',
          style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
        ),
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            final nuevo = await pedidoService.addPedido(
              idCliente: widget.pedido.idCliente,
            );
            if (nuevo != null) {
              await _crearLineasPedido(nuevo);
              final actualizado = await pedidoService.getPedido(
                idCliente: nuevo.idCliente,
                idPedido: nuevo.id,
              );
              if (actualizado != null) {
                _irAlPedidoConAnimacion(actualizado);
              }
            }
          } catch (e) {
            _showSnack('Error al clonar: $e', isError: true);
          }
        },
        confirmLabel: 'Clonar',
      ),
    );
  }

  void _irAlPedidoConAnimacion(Pedido nuevo) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PedidoDetailPage(pedido: nuevo)),
    );
  }

  Future<void> _crearLineasPedido(Pedido nuevo) async {
    for (final linea in List.from(lineas)) {
      try {
        await lineapedidoService.addLineaPedido(
          nuevo.idCliente,
          nuevo.id,
          linea.idProducto,
          linea.cantidad + (linea.stockFinal ?? 0),
          linea.precio,
          linea.grupo ?? 1,
        );
      } catch (e) {
        debugPrint('Error clonando linea ${linea.id}: $e');
      }
    }
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    final limpio = telefono.replaceAll(RegExp(r'\D'), '');
    if (limpio.isEmpty) {
      _showSnack('Teléfono no válido', isError: true);
      return;
    }
    final token = widget.pedido.token;
    if (token == null || token.isEmpty) {
      _showSnack('El pedido no tiene token público', isError: true);
      return;
    }
    final link = 'https://mi-app-deposito.cloud/pedido/download?token=$token';
    final url = Uri.parse(
      'https://wa.me/$limpio?text=${Uri.encodeComponent("Hola, aquí tienes el PDF de tu pedido:\n$link")}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('No se pudo abrir WhatsApp', isError: true);
    }
  }

  String formatFecha(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 18, color: _textSecondary),
      ),
    );
  }
}

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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLineaBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddLineaBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: _primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: _primary),
            const SizedBox(width: 8),
            Text(
              'Añadir nueva línea',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaTag extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool bold;
  const _LineaTag(
    this.label,
    this.value, {
    this.highlight = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 12, color: _textTertiary),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: highlight
                ? _warning
                : (bold ? _textPrimary : _textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SimpleField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType keyboardType;
  final bool autofocus;
  const _SimpleField({
    required this.ctrl,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      autofocus: autofocus,
      style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
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
    );
  }
}

// ─────────────────────────────────────────────
//  STYLED DIALOG
// ─────────────────────────────────────────────
class _StyledDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onClose;
  final Widget content;
  final Future<void> Function() onConfirm;
  final String confirmLabel;
  final Color confirmColor;

  const _StyledDialog({
    required this.title,
    required this.icon,
    this.iconColor = _primary,
    this.iconBg = _primaryLight,
    required this.onClose,
    required this.content,
    required this.onConfirm,
    required this.confirmLabel,
    this.confirmColor = _primary,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: _textTertiary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(width: 380, child: content),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  DATA HELPERS
// ─────────────────────────────────────────────
class _FinItem {
  final String label;
  final String value;
  final Color color;
  final Color accentColor;
  final String? sub;
  final bool bold;
  _FinItem(
    this.label,
    this.value,
    this.color, {
    required this.accentColor,
    this.sub,
    this.bold = false,
  });
}

// ─────────────────────────────────────────────
//  SKELETON
// ─────────────────────────────────────────────
class _Sk extends StatefulWidget {
  final double? width;
  final double height;
  const _Sk({this.width, required this.height});

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
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
