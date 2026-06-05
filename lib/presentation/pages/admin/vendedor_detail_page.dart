import 'package:expositor_app/core/session/session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/models/stats/ingreso_cliente.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

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

class VendedorDetailPage extends StatefulWidget {
  final Vendedor vendedor;
  final int title; // 1 = viene del admin dashboard, 0 = vista propia del user

  const VendedorDetailPage({
    super.key,
    required this.vendedor,
    required this.title,
  });

  @override
  State<VendedorDetailPage> createState() => _VendedorDetailPageState();
}

class _VendedorDetailPageState extends State<VendedorDetailPage> {
  final VendedorService vendedorService = VendedorService();

  late Future<Map<String, int>> _futureCategorias;
  late Future<List<IngresoCliente>> _futureGastosPorCliente;
  late Future<Map<String, int>> _futurePedidos;

  @override
  void initState() {
    super.initState();
    final int? idVendedor = Session.isAdmin ? widget.vendedor.id : null;
    _futureCategorias = vendedorService.getStatsProductsByCategory(
      idVendedor: idVendedor,
    );
    _futureGastosPorCliente = vendedorService.getIngresoAnualByCliente(
      idVendedor: idVendedor,
    );
    _futurePedidos = vendedorService.getNumPedidos(idVendedor: idVendedor);
  }

  String _getInitials() {
    final n = widget.vendedor.nombre.trim();
    final a = widget.vendedor.apellido.trim();
    return '${n.isNotEmpty ? n[0].toUpperCase() : ''}${a.isNotEmpty ? a[0].toUpperCase() : ''}';
  }

  // ─── BUILD ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, constraints) {
            final pad = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(pad),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 40),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVendedorCard(),
                            const SizedBox(height: 20),
                            _buildCategoriasSection(),
                            const SizedBox(height: 16),
                            _buildPedidosSection(),
                            const SizedBox(height: 16),
                            _buildClientesSection(constraints.maxWidth),
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
    );
  }

  // ─── HEADER ─────────────────────────────────
  Widget _buildHeader(double pad) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              children: [
                if (widget.title == 1) ...[
                  _IconBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.vendedor.nombre} ${widget.vendedor.apellido}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Estadísticas del vendedor',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textTertiary,
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

  // ─── VENDEDOR CARD ──────────────────────────
  Widget _buildVendedorCard() {
    final v = widget.vendedor;
    return _Card(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${v.nombre} ${v.apellido}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  v.email,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              v.role,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORÍAS SECTION ─────────────────────
  Widget _buildCategoriasSection() {
    return _SectionCard(
      title: 'Ventas por categoría',
      subtitle: 'Distribución de productos vendidos',
      child: FutureBuilder<Map<String, int>>(
        future: _futureCategorias,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildChartSkeleton(190);
          }
          if (snap.hasError) {
            return _ErrorWidget(message: 'Error al cargar categorías');
          }
          final ventas = snap.data ?? {};
          if (ventas.isEmpty) {
            return _EmptyWidget(message: 'No hay ventas registradas.');
          }
          return _buildDonutCategories(ventas);
        },
      ),
    );
  }

  // ─── PEDIDOS SECTION ────────────────────────
  Widget _buildPedidosSection() {
    return _SectionCard(
      title: 'Pedidos abiertos / cerrados',
      subtitle: 'Estado actual de los pedidos',
      child: FutureBuilder<Map<String, int>>(
        future: _futurePedidos,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildChartSkeleton(190);
          }
          if (snap.hasError) {
            return _ErrorWidget(message: 'Error al cargar pedidos');
          }
          final data = snap.data ?? {};
          final abiertos = data['abiertos'] ?? data['abierrtos'] ?? 0;
          final cerrados = data['cerrados'] ?? 0;
          if (abiertos == 0 && cerrados == 0) {
            return _EmptyWidget(message: 'No hay pedidos registrados.');
          }
          return _buildDonutPedidos(abiertos, cerrados);
        },
      ),
    );
  }

  // ─── CLIENTES SECTION ───────────────────────
  Widget _buildClientesSection(double pageWidth) {
    return _SectionCard(
      title: 'Ventas por cliente',
      subtitle: 'Importe total facturado por cliente',
      child: FutureBuilder<List<IngresoCliente>>(
        future: _futureGastosPorCliente,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildChartSkeleton(280);
          }
          if (snap.hasError) {
            return _ErrorWidget(message: 'Error al cargar ventas por cliente');
          }
          final ingresos = snap.data ?? [];
          if (ingresos.isEmpty) {
            return _EmptyWidget(message: 'No hay datos de ventas por cliente.');
          }
          return _buildBarChart(ingresos, pageWidth);
        },
      ),
    );
  }

  // ─── DONUT CATEGORÍAS ───────────────────────
  Widget _buildDonutCategories(Map<String, int> ventas) {
    final total = ventas.values.fold<int>(0, (a, b) => a + b);

    return SizedBox(
      height: 190,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                sections: ventas.entries.map((e) {
                  final pct = total == 0 ? 0 : (e.value * 100 / total).round();
                  return PieChartSectionData(
                    color: _colorForCategory(e.key),
                    value: e.value.toDouble(),
                    radius: 52,
                    title: '$pct%',
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ventas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = ventas.entries.elementAt(i);
                return _LegendRow(
                  color: _colorForCategory(e.key),
                  label: e.key,
                  value: e.value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── DONUT PEDIDOS ──────────────────────────
  Widget _buildDonutPedidos(int abiertos, int cerrados) {
    final total = abiertos + cerrados;
    final abPct = total == 0 ? 0 : (abiertos * 100 / total).round();
    final cePct = total == 0 ? 0 : (cerrados * 100 / total).round();

    return SizedBox(
      height: 190,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    color: _warning,
                    value: abiertos.toDouble(),
                    radius: 52,
                    title: '$abPct%',
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PieChartSectionData(
                    color: _success,
                    value: cerrados.toDouble(),
                    radius: 52,
                    title: '$cePct%',
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatPill(
                  label: 'Abiertos',
                  value: abiertos,
                  color: _warning,
                  bg: _warningLight,
                ),
                const SizedBox(height: 10),
                _StatPill(
                  label: 'Cerrados',
                  value: cerrados,
                  color: _success,
                  bg: _successLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BAR CHART ──────────────────────────────
  Widget _buildBarChart(List<IngresoCliente> ingresos, double pageWidth) {
    const double minBarW = 10;
    const double maxBarW = 34;
    const double barSpacing = 16;

    final double maxIngreso = ingresos
        .map((e) => e.total)
        .fold<double>(0, (max, v) => v > max ? v : max);

    double adaptiveW = pageWidth / ingresos.length.clamp(4, 10);
    adaptiveW = adaptiveW.clamp(minBarW, maxBarW);

    final double chartW = ingresos.length * (adaptiveW + barSpacing) + 40;

    final double maxY = maxIngreso <= 0 ? 1 : maxIngreso * 1.15;
    final double interval = maxY <= 4 ? 1 : maxY / 4;

    return SizedBox(
      height: 300,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: chartW,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.start,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, _, rod, __) {
                    final ing = ingresos[group.x.toInt()];
                    return BarTooltipItem(
                      '${ing.clienteNombre}\n',
                      GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toStringAsFixed(2)} €',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: _border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= ingresos.length) {
                        return const SizedBox.shrink();
                      }
                      return Transform.rotate(
                        angle: -0.6,
                        child: Text(
                          ingresos[i].clienteNombre,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(ingresos.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barsSpace: barSpacing,
                  barRods: [
                    BarChartRodData(
                      toY: ingresos[i].total.toDouble(),
                      width: adaptiveW,
                      borderRadius: BorderRadius.circular(6),
                      color: _primary,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: _primaryLight,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CHART SKELETON ─────────────────────────
  Widget _buildChartSkeleton(double height) {
    return _Sk(width: double.infinity, height: height);
  }

  // ─── COLORS ─────────────────────────────────
  Color _colorForCategory(String cat) {
    switch (cat.toUpperCase()) {
      case 'COLLAR':
        return _primary;
      case 'PULSERA':
        return const Color(0xFFEC4899);
      case 'ANILLO':
        return _warning;
      case 'CORDAJE':
        return _success;
      default:
        return _textTertiary;
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, required this.child});

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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(fontSize: 12, color: _textTertiary),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
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

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ),
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 12, color: _error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final String message;
  const _EmptyWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: _textTertiary),
          const SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }
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
