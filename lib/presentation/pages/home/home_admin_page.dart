import 'dart:ui' show lerpDouble;

import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/auth_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/presentation/pages/admin/cliente/cliente_page.dart';
import 'package:expositor_app/presentation/pages/admin/dashboard_admin_page.dart';
import 'package:expositor_app/presentation/pages/admin/config/config_vendedor_admin_page.dart';
import 'package:expositor_app/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage>
    with TickerProviderStateMixin {
  final VendedorService _vendedorService = VendedorService();

  Vendedor? _vendedorActual;
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final List<_NavItem> _navItems;
  final _clientesKey = GlobalKey<ClientesPageState>();

  // Sidebar: 0.0 = contraído (80px), 1.0 = expandido (280px)
  late AnimationController _sidebarController;

  bool get _sidebarExpanded => _sidebarController.value > 0.5;
  bool get _showSidebarText => _sidebarController.value > 0.7;
  double get _sidebarWidth => lerpDouble(80, 280, _sidebarController.value)!;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: 1.0, // empieza expandido
    )..addListener(() => setState(() {}));

    _navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      _NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Clientes',
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Configuración',
      ),
    ];
    _loadMe();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sidebarController.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });

    try {
      final vendedor = await _vendedorService.getMe();

      if (!mounted) return;

      if (vendedor == null) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMessage = 'No se pudo cargar tu perfil. Verifica tu conexión.';
        });
        return;
      }

      setState(() {
        _vendedorActual = vendedor;
        _loading = false;
        _error = false;
      });

      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = 'Error de conexión. Por favor intenta de nuevo.';
      });
    }
  }

  void _toggleSidebar() {
    if (_sidebarController.value == 1.0) {
      _sidebarController.reverse();
    } else {
      _sidebarController.forward();
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    // Refresca clientes al volver al tab para mostrar cambios desde Configuración
    if (index == 1) {
      _clientesKey.currentState?.refresh();
    }
  }

  Future<void> _onLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildLoadingState(),
      );
    }

    if (_error || _vendedorActual == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildErrorState(),
      );
    }

    final vendedor = _vendedorActual!;
    final name = '${vendedor.nombre} ${vendedor.apellido}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          return isDesktop
              ? _buildDesktopLayout(vendedor, name)
              : _buildMobileTabletLayout(vendedor, name);
        },
      ),
    );
  }

  // ============== LOADING STATE ==============
  Widget _buildLoadingState() {
    return SafeArea(
      child: Column(
        children: [
          _buildShimmerAppBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 200, height: 28),
                  const SizedBox(height: 20),
                  _buildShimmerBox(width: double.infinity, height: 120),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildShimmerBox(height: 100)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildShimmerBox(height: 100)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildShimmerBox(width: double.infinity, height: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerAppBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF2b2b2b)),
      child: Row(
        children: [
          _buildShimmerCircle(40),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 80, height: 12, color: Colors.white24),
              const SizedBox(height: 6),
              _buildShimmerBox(width: 120, height: 16, color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    double? width,
    double height = 16,
    Color color = const Color(0xFFE2E8F0),
  }) {
    return _ShimmerBox(width: width, height: height, color: color);
  }

  Widget _buildShimmerCircle(double size) {
    return _ShimmerCircle(size: size);
  }

  // ============== ERROR STATE ==============
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Algo salió mal',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'No se pudo cargar tu perfil.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _AnimatedRetryButton(onPressed: _loadMe),
          ],
        ),
      ),
    );
  }

  // ============== DESKTOP LAYOUT ==============
  Widget _buildDesktopLayout(Vendedor vendedor, String name) {
    return Row(
      children: [
        SizedBox(width: _sidebarWidth, child: _buildSidebar(vendedor, name)),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: IndexedStack(
              index: _selectedIndex,
              children: _buildPages(vendedor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(Vendedor vendedor, String name) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con info del vendedor
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExpanded ? 16 : 12,
              vertical: 16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(name),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_showSidebarText) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vendedor.email,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Toggle sidebar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExpanded ? 16 : 14,
            ),
            child: InkWell(
              onTap: _toggleSidebar,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: _sidebarExpanded ? 12 : 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: _sidebarExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    AnimatedRotation(
                      turns: _sidebarExpanded ? 0 : 0.5,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 22,
                      ),
                    ),
                    if (_showSidebarText) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Contraer menú',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation items
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = _selectedIndex == index;
            return _buildSidebarItem(
              item: item,
              isSelected: isSelected,
              onTap: () => _onItemTapped(index),
            );
          }),

          const Spacer(),

          // Logout
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExpanded ? 12 : 14,
              vertical: 16,
            ),
            child: _buildLogoutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Tooltip(
      message: 'Cerrar sesión',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onLogout,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExpanded ? 16 : 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: _sidebarExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade300,
                  size: 22,
                ),
                if (_showSidebarText) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Cerrar sesión',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required _NavItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _sidebarExpanded ? 12 : 14,
        vertical: 4,
      ),
      child: Tooltip(
        message: _sidebarExpanded ? '' : item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: _sidebarExpanded ? 16 : 12,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: _sidebarExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      color: isSelected ? Colors.white : Colors.white60,
                      size: 22,
                    ),
                  ),
                  if (_showSidebarText) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============== MOBILE/TABLET LAYOUT ==============
  Widget _buildMobileTabletLayout(Vendedor vendedor, String name) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildMobileAppBar(vendedor, name),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _selectedIndex,
          children: _buildPages(vendedor),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon, color: const Color(0xFF94A3B8)),
                selectedIcon: Icon(
                  item.activeIcon,
                  color: const Color(0xFF6366F1),
                ),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileAppBar(Vendedor vendedor, String name) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(name),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vendedor.email,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _onLogout,
                tooltip: 'Cerrar sesión',
                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade300,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  List<Widget> _buildPages(Vendedor vendedor) {
    return [
      const VendedoresDashboardPage(),
      ClientesPage(key: _clientesKey),
      ConfigVendedorPage(vendedorActual: vendedor),
    ];
  }
}

// ============== HELPER CLASSES ==============

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final Color color;

  const _ShimmerBox({
    this.width,
    this.height = 16,
    this.color = const Color(0xFFE2E8F0),
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatefulWidget {
  final double size;

  const _ShimmerCircle({required this.size});

  @override
  State<_ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<_ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_animation.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AnimatedRetryButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const _AnimatedRetryButton({required this.onPressed});

  @override
  State<_AnimatedRetryButton> createState() => _AnimatedRetryButtonState();
}

class _AnimatedRetryButtonState extends State<_AnimatedRetryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _controller.repeat();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.refresh_rounded, size: 20),
            )
          else
            const Icon(Icons.refresh_rounded, size: 20),
          const SizedBox(width: 8),
          Text(
            _isLoading ? 'Cargando...' : 'Reintentar',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
