import 'package:expositor_app/core/services/file_saver.dart';
import 'package:expositor_app/data/services/parametros_globales_service.dart';
import 'package:expositor_app/utils/download/download_web.dart';
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
  int? filtroGrupo = null;
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

  Future<void> _loadAll() async {
    setState(() {
      loadingLineas = true;
    });

    await _loadCliente();
    await _loadLineasPedido();

    grupoMaxConfig = await paramService.getGrupoMax();

    _aplicarFiltro();
  }

  void _aplicarFiltro() {
    setState(() {
      if (filtroGrupo == null) {
        lineasFiltradas = List.from(lineas);
      } else {
        lineasFiltradas = lineas.where((l) => l.grupo == filtroGrupo).toList();
      }
    });
  }

  Future<void> _loadCliente() async {
    final cli = await clienteService.getClienteById(widget.pedido.idCliente);
    setState(() => cliente = cli);
  }

  Future<void> _loadLineasPedido() async {
    setState(() => loadingLineas = true);

    final result = await lineapedidoService.getLineasPedido(
      widget.pedido.idCliente,
      widget.pedido.id,
    );

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

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Pedido #${pedido.id}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (pedido.cerrado)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    "Cerrado",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    "Abierto",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: cliente == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPedido,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
                  vertical: 20,
                ),
                children: [
                  // Info Card compacta
                  _buildInfoCardCompact(pedido, cliente!),

                  const SizedBox(height: 20),

                  // Comentario Card (solo si pedido abierto o tiene comentario)
                  if (!widget.pedido.cerrado ||
                      widget.pedido.comentario.isNotEmpty)
                    _buildComentarioCard(),

                  if (!widget.pedido.cerrado ||
                      widget.pedido.comentario.isNotEmpty)
                    const SizedBox(height: 20),

                  // Lineas Card
                  _buildLineasCard(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ===========================================================
  //                  CARD INFORMACION COMPACTA
  // ===========================================================
  Widget _buildInfoCardCompact(Pedido pedido, Cliente cliente) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente y Fecha en una fila
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C75EF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF3C75EF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        cliente.cif,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatFecha(pedido.fecha),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // Datos financieros en grid
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: _buildFinanceItem("Bruto Total", pedido.brutoTotal),
                  ),
                  Expanded(
                    child: _buildFinanceItem(
                      "Base Imponible",
                      pedido.baseImponible,
                      subtitle: "${pedido.descuento}% dto.",
                    ),
                  ),
                  Expanded(
                    child: _buildFinanceItem(
                      "IVA",
                      pedido.precioIva,
                      subtitle: "${pedido.iva}%",
                    ),
                  ),
                  Expanded(child: _buildTotalItem("Total Final", pedido.total)),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinanceItem(
                          "Bruto Total",
                          pedido.brutoTotal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFinanceItem(
                          "Base Imponible",
                          pedido.baseImponible,
                          subtitle: "${pedido.descuento}% dto.",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinanceItem(
                          "IVA",
                          pedido.precioIva,
                          subtitle: "${pedido.iva}%",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTotalItem("Total Final", pedido.total),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Botones de accion
            _buildResponsiveActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceItem(String label, String value, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${value} \u20AC",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C75EF), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${value} \u20AC",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //                    CARD COMENTARIO
  // ===========================================================
  Widget _buildComentarioCard() {
    final bool isCerrado = widget.pedido.cerrado;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.comment_outlined,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Comentario",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 3,
              readOnly: isCerrado,
              decoration: InputDecoration(
                hintText: isCerrado
                    ? "Sin comentarios"
                    : "Escribe un comentario para este pedido...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3C75EF),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isCerrado ? Colors.grey.shade50 : Colors.white,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            if (!isCerrado) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: _guardandoComentario
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _guardandoComentario ? "Guardando..." : "Guardar",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C75EF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _guardandoComentario ? null : _guardarComentario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _guardarComentario() async {
    final text = _comentarioCtrl.text.trim();

    setState(() => _guardandoComentario = true);

    final ok = await pedidoService.putComentario(
      idCliente: widget.pedido.idCliente,
      idPedido: widget.pedido.id,
      comentario: text,
    );

    setState(() => _guardandoComentario = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Comentario actualizado", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refreshPedido();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error al actualizar el comentario",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================
  //                    CARD LINEAS DEL PEDIDO
  // ===========================================================
  Widget _buildLineasCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C75EF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.list_alt,
                    color: Color(0xFF3C75EF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Lineas del Pedido",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                // Contador de lineas
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${lineasFiltradas.length} items",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filtro por grupo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: filtroGrupo,
                  isExpanded: false,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("Todos los grupos"),
                    ),
                    ...List.generate(
                      grupoMaxConfig,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text("Grupo ${i + 1}"),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filtroGrupo = value;
                      _aplicarFiltro();
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boton anadir linea
            if (!widget.pedido.cerrado) _buildAddLineaButton(),

            if (!widget.pedido.cerrado) const SizedBox(height: 16),

            // Lista de lineas
            if (loadingLineas)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (lineasFiltradas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No hay lineas registradas",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lineasFiltradas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _buildLineaItem(lineasFiltradas[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddLineaButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _showAddLineaDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3C75EF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF3C75EF).withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3C75EF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              "Anadir nueva linea",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3C75EF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //                    ITEM DE LINEA (DESTACAR SIN STOCK)
  // ===========================================================
  Widget _buildLineaItem(LineaPedido linea) {
    final bool sinStockFinal = linea.stockFinal == null;

    return FutureBuilder(
      future: productoService.getProducto(linea.idProducto),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final Producto producto = snapshot.data!;
        final String totalLinea = (linea.precio * linea.cantidad)
            .toStringAsFixed(2);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sinStockFinal ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sinStockFinal
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: sinStockFinal ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onDoubleTap: widget.pedido.cerrado
                ? null
                : () => _showEditLineaDialog(linea),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono producto
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sinStockFinal
                        ? Colors.orange.shade100
                        : const Color(0xFF3C75EF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: sinStockFinal
                        ? Colors.orange.shade700
                        : const Color(0xFF3C75EF),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                // Info linea
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre producto + grupo
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              producto.descripcion,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (linea.grupo != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "G${linea.grupo}",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Cantidad, precio, stock
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _buildLineaDetail(
                            "Cantidad",
                            linea.cantidad.toString(),
                          ),
                          _buildLineaDetail(
                            "Precio",
                            "${linea.precio.toStringAsFixed(2)} \u20AC",
                          ),
                          _buildLineaDetail(
                            "Stock Final",
                            linea.stockFinal?.toString() ?? "Pendiente",
                            highlight: sinStockFinal,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Total linea
                      Row(
                        children: [
                          Text(
                            "Total: ",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "$totalLinea \u20AC",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botones accion
                if (!widget.pedido.cerrado)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Actualizar stock final",
                        icon: Icon(
                          Icons.edit_note,
                          color: sinStockFinal
                              ? Colors.orange.shade700
                              : Colors.blue,
                        ),
                        onPressed: () => _showStockFinalDialog(context, linea),
                      ),
                      IconButton(
                        tooltip: "Eliminar linea",
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                        onPressed: () => _confirmDeleteLinea(linea),
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

  Widget _buildLineaDetail(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: highlight ? Colors.orange.shade700 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  //                    BOTONES DE ACCION
  // ===========================================================
  Widget _buildResponsiveActionButton() {
    if (widget.pedido.cerrado) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildActionButton(
            icon: Icons.copy,
            label: "Clonar",
            color: const Color(0xFF3C75EF),
            onPressed: () => _clonarPedido(context),
          ),
          _buildActionButton(
            icon: Icons.picture_as_pdf,
            label: "PDF",
            color: Colors.green,
            onPressed: _descargarPedidoPdf,
          ),
          if (cliente?.telefono != null && cliente!.telefono.isNotEmpty)
            _buildActionButton(
              icon: Icons.chat,
              label: "WhatsApp",
              color: const Color(0xFF25D366),
              onPressed: () => _abrirWhatsApp(cliente!.telefono),
            ),
        ],
      );
    }

    return _buildActionButton(
      icon: Icons.lock_outline,
      label: "Cerrar Pedido",
      color: Colors.red.shade400,
      onPressed: _confirmCerrarPedido,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      onPressed: onPressed,
    );
  }

  // ===========================================================
  //                    DIALOGS Y FUNCIONES
  // ===========================================================

  void _showAddLineaDialog() async {
    Producto? productoSeleccionado;
    TextEditingController unidadesCtrl = TextEditingController();
    TextEditingController precioCtrl = TextEditingController();

    int grupoSeleccionado = filtroGrupo ?? 1;
    int grupoMax = 1;

    grupoMax = await paramService.getGrupoMax();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Anadir linea al pedido",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final seleccionado = await _showProductoSelector();
                      if (seleccionado != null) {
                        setStateDialog(() {
                          productoSeleccionado = seleccionado;
                          precioCtrl.text = seleccionado.precio.toString();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productoSeleccionado?.descripcion ??
                                "Seleccionar producto",
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: unidadesCtrl,
                    decoration: InputDecoration(
                      labelText: "Unidades",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: precioCtrl,
                    decoration: InputDecoration(
                      labelText: "Precio unitario",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: grupoSeleccionado,
                    decoration: InputDecoration(
                      labelText: "Grupo",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: List.generate(
                      grupoMax,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text("Grupo ${i + 1}"),
                      ),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        grupoSeleccionado = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C75EF),
                  ),
                  child: const Text("Guardar"),
                  onPressed: () async {
                    if (productoSeleccionado == null ||
                        unidadesCtrl.text.isEmpty ||
                        precioCtrl.text.isEmpty)
                      return;

                    final nuevaLinea = await lineapedidoService.addLineaPedido(
                      widget.pedido.idCliente,
                      widget.pedido.id,
                      productoSeleccionado!.id,
                      int.parse(unidadesCtrl.text),
                      double.parse(precioCtrl.text),
                      grupoSeleccionado,
                    );

                    Navigator.pop(dialogContext);

                    if (nuevaLinea != null) await _refreshPedido();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Producto?> _showProductoSelector() async {
    List<Producto> productos = await productoService.getAllProductos();
    List<Producto> filtrados = List.from(productos);
    TextEditingController searchCtrl = TextEditingController();

    return showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: "Buscar por nombre o categoria",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setStateSheet(() {
                        final query = value.toLowerCase();
                        filtrados = productos.where((p) {
                          final nameMatch = p.descripcion
                              .toLowerCase()
                              .contains(query);
                          final catMatch = (p.categoria ?? "")
                              .toLowerCase()
                              .contains(query);
                          return nameMatch || catMatch;
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final p = filtrados[index];

                        return ListTile(
                          title: Text(
                            p.descripcion,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${p.precio.toStringAsFixed(2)} \u20AC",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              if (p.categoria != null)
                                Text(
                                  "Categoria: ${p.categoria}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditLineaDialog(LineaPedido linea) async {
    final producto = await productoService.getProducto(linea.idProducto);

    TextEditingController cantidadCtrl = TextEditingController(
      text: linea.cantidad.toString(),
    );
    TextEditingController precioCtrl = TextEditingController(
      text: linea.precio.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Editar linea",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto?.descripcion ?? "Sin descripcion",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Cantidad",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: precioCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Precio unitario",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancelar", style: GoogleFonts.poppins()),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C75EF),
              ),
              child: Text("Guardar", style: GoogleFonts.poppins()),
              onPressed: () async {
                final cantidad = int.tryParse(cantidadCtrl.text);
                final precio = double.tryParse(precioCtrl.text);

                if (cantidad == null || precio == null) return;

                Navigator.pop(dialogContext);

                final updated = await lineapedidoService.updateLineaPedido(
                  widget.pedido.idCliente,
                  widget.pedido.id,
                  linea.id,
                  cantidad,
                  precio,
                );

                if (updated != null) {
                  await _refreshPedido();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLinea(LineaPedido linea) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Eliminar linea",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Seguro que quieres eliminar esta linea?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: Text("Cancelar", style: GoogleFonts.poppins()),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Eliminar", style: GoogleFonts.poppins()),
              onPressed: () async {
                Navigator.pop(context);

                final ok = await lineapedidoService.deleteLineaPedido(
                  widget.pedido.idCliente,
                  widget.pedido.id,
                  linea.id,
                );

                if (ok) {
                  await _refreshPedido();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al eliminar la linea"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmCerrarPedido() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Cerrar pedido",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Seguro que quieres cerrar este pedido?\n\nUna vez cerrado, no podras modificar lineas.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar", style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);

                final ok = await pedidoService.cerrarPedido(
                  widget.pedido.idCliente,
                  widget.pedido.id,
                );

                if (ok) {
                  await _refreshPedido();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al cerrar el pedido"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                "Cerrar",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStockFinalDialog(BuildContext context, LineaPedido linea) {
    final controller = TextEditingController(
      text: linea.stockFinal?.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Stock final",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Introduce el nuevo stock",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C75EF),
              ),
              onPressed: () async {
                final texto = controller.text.trim();

                if (texto.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("El stock no puede estar vacio"),
                    ),
                  );
                  return;
                }

                final nuevoStock = int.tryParse(texto);

                if (nuevoStock == null || nuevoStock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Introduce un numero valido")),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final ok = await LineaPedidoService.actualizarStockFinal(
                  idCliente: widget.pedido.idCliente,
                  idPedido: widget.pedido.id,
                  idLinea: linea.id,
                  stockFinal: nuevoStock,
                );

                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Stock actualizado correctamente"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    linea.stockFinal = nuevoStock;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al actualizar el stock"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _descargarPedidoPdf() async {
    final bytes = await PedidoService.descargarPedidoPdf(
      idCliente: widget.pedido.idCliente,
      idPedido: widget.pedido.id,
    );

    if (bytes != null) {
      await downloadBytes(bytes, "PedidoPDF.pdf");
    }
  }

  void _clonarPedido(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Clonar pedido",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Quieres realmente clonar este pedido?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancelar", style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C75EF),
              ),
              onPressed: () async {
                Navigator.pop(ctx);

                try {
                  final pedidoNuevo = await pedidoService.addPedido(
                    idCliente: widget.pedido.idCliente,
                  );

                  if (pedidoNuevo != null) {
                    await _crearLineasPedido(pedidoNuevo);

                    final pedidoActualizado = await pedidoService.getPedido(
                      idCliente: pedidoNuevo.idCliente,
                      idPedido: pedidoNuevo.id,
                    );
                    if (pedidoActualizado != null) {
                      _irAlPedidoConAnimacion(pedidoActualizado);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error al refrescar el pedido clonado"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error al clonar el pedido"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                "Clonar",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _irAlPedidoConAnimacion(Pedido nuevo) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PedidoDetailPage(pedido: nuevo)),
    );
  }

  Future<void> _crearLineasPedido(Pedido pedidoNuevo) async {
    final List<LineaPedido> origen = List.from(lineas);

    if (origen.isEmpty) return;

    for (final linea in origen) {
      try {
        await lineapedidoService.addLineaPedido(
          pedidoNuevo.idCliente,
          pedidoNuevo.id,
          linea.idProducto,
          linea.cantidad + (linea.stockFinal ?? 0),
          linea.precio,
          linea.grupo ?? 1,
        );
      } catch (e) {
        debugPrint("Error clonando linea ${linea.id}: $e");
      }
    }
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    if (telefono.trim().isEmpty) return;

    final telefonoLimpio = telefono.replaceAll(RegExp(r'\D'), '');

    if (telefonoLimpio.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("El teléfono no es válido")));
      return;
    }

    final token = widget.pedido.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El pedido no tiene token público")),
      );
      return;
    }
    //TODO CAMBIAR ESTO AL TENER DOMINIO O IP STATICA
    final linkPdf = "http://192.168.1.103:8080/pedido/public/pdf?token=$token";

    final mensaje = "Hola, aquí tienes el PDF de tu pedido: $linkPdf";

    final url = Uri.parse(
      "https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }

  String formatFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (_) {
      return fechaISO;
    }
  }
}
