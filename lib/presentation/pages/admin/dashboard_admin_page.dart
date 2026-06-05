import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/presentation/widget/cards/vendor_card.dart';
import 'package:expositor_app/presentation/pages/admin/vendedor_detail_page.dart';

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
const _error = Color(0xFFEF4444);
const _errorLight = Color(0xFFFEF2F2);

class VendedoresDashboardPage extends StatefulWidget {
  const VendedoresDashboardPage({super.key});

  @override
  State<VendedoresDashboardPage> createState() =>
      _VendedoresDashboardPageState();
}

class _VendedoresDashboardPageState extends State<VendedoresDashboardPage> {
  final VendedorService _service = VendedorService();

  List<Vendedor> _vendedores = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final lista = await _service.getVendedores();
      if (!mounted) return;
      setState(() {
        _vendedores = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  int _crossAxisCount(double width) {
    if (width < 690) return 1;
    if (width < 1100) return 2;
    if (width < 1500) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, constraints) {
            final pad = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return RefreshIndicator(
              onRefresh: _load,
              color: _primary,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 24, pad, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dashboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _loading
                                      ? 'Cargando vendedores…'
                                      : '${_vendedores.length} vendedor${_vendedores.length == 1 ? '' : 'es'} activos',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Refresh button
                          Tooltip(
                            message: 'Actualizar',
                            child: InkWell(
                              onTap: _loading ? null : _load,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _border),
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: _loading
                                      ? _textTertiary
                                      : _textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ─────────────────────────
                  if (_loading)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const _VendorCardSkeleton(),
                          childCount: 4,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount(constraints.maxWidth),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 200,
                        ),
                      ),
                    )
                  else if (_hasError)
                    SliverFillRemaining(child: _buildErrorState())
                  else if (_vendedores.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((_, i) {
                          final v = _vendedores[i];
                          return VendorCard(
                            vendedor: v,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VendedorDetailPage(vendedor: v, title: 1),
                              ),
                            ),
                          );
                        }, childCount: _vendedores.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount(constraints.maxWidth),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 200,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _errorLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cloud_off_rounded, color: _error, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'Error al cargar los vendedores',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tira hacia abajo para reintentar.',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Reintentar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin vendedores',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay vendedores registrados aún.',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Skeleton card para loading
// ─────────────────────────────────────────────
class _VendorCardSkeleton extends StatefulWidget {
  const _VendorCardSkeleton();

  @override
  State<_VendorCardSkeleton> createState() => _VendorCardSkeletonState();
}

class _VendorCardSkeletonState extends State<_VendorCardSkeleton>
    with SingleTickerProviderStateMixin {
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

  Widget _sk({double? width, required double height, double radius = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sk(width: 44, height: 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sk(width: 120, height: 14),
                    const SizedBox(height: 6),
                    _sk(width: 160, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 16),
          Row(
            children: [
              _sk(width: 80, height: 80, radius: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _sk(width: double.infinity, height: 32, radius: 8),
                    const SizedBox(height: 10),
                    _sk(width: double.infinity, height: 32, radius: 8),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
