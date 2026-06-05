import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

// ─────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────
const _surface = Color(0xFFFFFFFF);
const _bg = Color(0xFFF8FAFC);
const _border = Color(0xFFE2E8F0);
const _primary = Color(0xFF2563EB);
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _textTertiary = Color(0xFF94A3B8);
const _success = Color(0xFF22C55E);
const _successLight = Color(0xFFF0FDF4);
const _warning = Color(0xFFF59E0B);
const _warningLight = Color(0xFFFFFBEB);
const _error = Color(0xFFEF4444);
const _errorLight = Color(0xFFFEF2F2);

class VendorCard extends StatefulWidget {
  final Vendedor vendedor;
  final VoidCallback onTap;

  const VendorCard({super.key, required this.vendedor, required this.onTap});

  @override
  State<VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  final VendedorService _service = VendedorService();
  late Future<Map<String, int>> _futurePedidos;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _futurePedidos = _service.getNumPedidos(idVendedor: widget.vendedor.id);
  }

  String _getInitials() {
    final n = widget.vendedor.nombre.trim();
    final a = widget.vendedor.apellido.trim();
    final ni = n.isNotEmpty ? n[0].toUpperCase() : '';
    final ai = a.isNotEmpty ? a[0].toUpperCase() : '';
    return '$ni$ai'.isNotEmpty ? '$ni$ai' : '?';
  }

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
                      color: _primary.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
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
          child: FutureBuilder<Map<String, int>>(
            future: _futurePedidos,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildLoading();
              }
              if (snap.hasError) {
                return _buildError();
              }
              final data = snap.data ?? {};
              final abiertos = data['abiertos'] ?? data['abierrtos'] ?? 0;
              final cerrados = data['cerrados'] ?? 0;
              return _buildContent(abiertos, cerrados);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(int abiertos, int cerrados) {
    final v = widget.vendedor;
    final total = abiertos + cerrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: avatar + nombre + email ──
        Row(
          children: [
            // Initials avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                _getInitials(),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.nombre} ${v.apellido}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v.email,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

        const SizedBox(height: 12),
        const Divider(height: 1, color: _border),
        const SizedBox(height: 12),

        // ── Donut chart + stats ──────────────
        Expanded(
          child: Row(
            children: [
              // Donut chart
              SizedBox(
                width: 80,
                height: 80,
                child: total == 0
                    ? _buildEmptyChart()
                    : PieChart(
                        PieChartData(
                          centerSpaceRadius: 26,
                          sectionsSpace: 2,
                          sections: [
                            PieChartSectionData(
                              color: _warning,
                              value: abiertos.toDouble(),
                              title: '',
                              radius: 20,
                            ),
                            PieChartSectionData(
                              color: _success,
                              value: cerrados.toDouble(),
                              title: '',
                              radius: 20,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Stats
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
                    const SizedBox(height: 8),
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
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 8),
        color: _bg,
      ),
      alignment: Alignment.center,
      child: Text(
        '0',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textTertiary,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 140,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _border),
        const SizedBox(height: 16),
        const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _errorLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.wifi_off_rounded, color: _error, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          'Error al cargar',
          style: GoogleFonts.poppins(fontSize: 12, color: _error),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Stat pill
// ─────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
