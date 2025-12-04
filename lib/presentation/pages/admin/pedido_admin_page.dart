import 'package:expositor_app/data/models/linea_pedido.dart';
import 'package:expositor_app/data/services/linea_pedido_service.dart';
import 'package:expositor_app/data/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/services/cliente_service.dart';

class PedidoAdminDetailPage extends StatefulWidget {
  final Pedido pedido;

  const PedidoAdminDetailPage({super.key, required this.pedido});

  @override
  State<PedidoAdminDetailPage> createState() => _PedidoAdminDetailPageState();
}

class _PedidoAdminDetailPageState extends State<PedidoAdminDetailPage> {
  Cliente? cliente;
  final ClienteService clienteService = ClienteService();
  final LineaPedidoService lineapedidoService = LineaPedidoService();
  final ProductoService productoService = ProductoService();

  @override
  void initState() {
    super.initState();
    _loadCliente();
  }

  Future<void> _loadCliente() async {
    final cli = await clienteService.getClienteById(widget.pedido.idCliente);
    setState(() => cliente = cli);
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C75EF),
        centerTitle: true,
        title: Text(
          "Pedido #${pedido.id}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          // ---------- ICONO PRINCIPAL ----------
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ---------- TÍTULO ----------
          Center(
            child: Text(
              "Pedido #${pedido.id}",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ---------- FECHA ----------
          Center(
            child: Text(
              formatFecha(pedido.fecha),
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 30),

          if (cliente != null)
            _buildInfoCard(pedido, cliente!)
          else
            const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 30),
          _buildLineasCard(),
        ],
      ),
    );
  }

  Widget _buildLineasCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Líneas del pedido",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            FutureBuilder(
              future: lineapedidoService.getLineasPedido(
                widget.pedido.idCliente,
                widget.pedido.id,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lineas = snapshot.data!;

                if (lineas.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay líneas registradas",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < lineas.length; i++) ...[
                      _buildLineaReal(lineas[i]),
                      if (i < lineas.length - 1)
                        const Divider(height: 30, thickness: 1),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineaReal(LineaPedido linea) {
    return FutureBuilder(
      future: productoService.getProducto(linea.idProducto),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final producto = snapshot.data!;
        final totalLinea = (linea.precio * linea.cantidad).toStringAsFixed(2);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------ ICONO NUMERO LINEA ------------
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: Colors.blue,
                size: 22,
              ),
            ),

            const SizedBox(width: 15),

            // ------------ DATOS DE LA LÍNEA ------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.descripcion,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Cantidad: ${linea.cantidad}",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    "Precio unitario: ${linea.precio.toStringAsFixed(2)} €",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Total línea: $totalLinea €",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLineaItem(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número de línea
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              index.toString(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Datos de la línea (por ahora solo ID)
        Expanded(
          child: Text(
            "Línea ID: ${widget.pedido.idLineaPedido[index - 1]}",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================
  //                     CARD DE INFORMACIÓN
  // ===========================================================
  Widget _buildInfoCard(Pedido pedido, Cliente cliente) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ------------------- COLUMNA IZQUERDA -------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleItem("Bruto total:", "${pedido.brutoTotal} €"),
                  const SizedBox(height: 18),

                  _titleItem(
                    "Base imponible:",
                    "${pedido.baseImponible} €   •   ${pedido.descuento}%",
                  ),
                  const SizedBox(height: 18),

                  _titleItem(
                    "IVA:",
                    "${pedido.precioIva} €   •   ${pedido.iva}%",
                  ),
                  const SizedBox(height: 18),

                  _titleItem("Total final:", "${pedido.total} €"),
                  const SizedBox(height: 18),

                  _titleItem(
                    "Num de líneas:",
                    pedido.idLineaPedido.length.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 40),

            // ------------------- COLUMNA DERECHA -------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleItem("ID del pedido:", pedido.id.toString()),
                  const SizedBox(height: 18),

                  _titleItem("Cliente:", "${cliente.nombre} - ${cliente.cif}"),
                  const SizedBox(height: 18),

                  _titleItem("Fecha:", formatFecha(pedido.fecha)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //                 WIDGET PARA MOSTRAR UNA FILA
  // ===========================================================
  Widget _titleItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  //                    FORMATEAR FECHA
  // ===========================================================
  String formatFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (e) {
      return fechaISO;
    }
  }
}
