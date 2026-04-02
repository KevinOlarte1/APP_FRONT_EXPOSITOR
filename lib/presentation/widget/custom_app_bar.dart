import 'package:expositor_app/core/constants/app_colors.dart';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppBar mejorado con:
/// - Dropdown de perfil animado (en lugar de solo logout)
/// - Indicador de estado online/offline
/// - Animaciones suaves en hover/tap
/// - Mejor jerarquía visual
/// - Notificaciones badge (opcional)
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String name;
  final String avatarUrl;
  final String? email;
  final String? role;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final int notificationCount;
  final bool isOnline;

  const CustomAppBar({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.email,
    this.role,
    this.onLogout,
    this.onProfileTap,
    this.onSettingsTap,
    this.notificationCount = 0,
    this.isOnline = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  final GlobalKey _avatarKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final RenderBox? renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop para cerrar el menu
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu dropdown
          Positioned(
            top: position.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - position.dx - size.width,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: _buildDropdownMenu(context),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() => _isMenuOpen = true);
  }

  void _removeOverlay() {
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
    setState(() => _isMenuOpen = false);
  }

  Widget _buildDropdownMenu(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF363636),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del menu con info del usuario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  _buildAvatar(radius: 24, showStatus: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.email != null)
                          Text(
                            widget.email!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.role != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.role!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Opciones del menu
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Mi Perfil',
              onTap: () {
                _removeOverlay();
                widget.onProfileTap?.call();
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              label: 'Configuracion',
              onTap: () {
                _removeOverlay();
                widget.onSettingsTap?.call();
              },
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
            ),

            // Logout
            _buildMenuItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesion',
              isDestructive: true,
              onTap: () {
                _removeOverlay();
                _confirmarLogout(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color.withOpacity(0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({double radius = 20, bool showStatus = true}) {
    final String initials = _initialsFromName(widget.name);
    final bool hasAvatar = widget.avatarUrl.trim().isNotEmpty;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isMenuOpen
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: _isMenuOpen
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFF4A4A4A),
            backgroundImage: hasAvatar ? NetworkImage(widget.avatarUrl) : null,
            child: hasAvatar
                ? null
                : Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: radius * 0.7,
                    ),
                  ),
          ),
        ),
        // Indicador de estado online
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.isOnline ? const Color(0xFF22C55E) : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2b2b2b), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Breakpoints
    const double mobileMax = 600;
    const double tabletMax = 1024;

    final bool isMobile = width < mobileMax;
    final bool isTablet = width >= mobileMax && width < tabletMax;

    // Responsive metrics
    final double horizontalPadding = isMobile
        ? 16
        : isTablet
        ? 24
        : 32;
    final double spacing = isMobile
        ? 10
        : isTablet
        ? 14
        : 18;
    final double greetingFontSize = isMobile
        ? 11
        : isTablet
        ? 12
        : 13;
    final double nameFontSize = isMobile
        ? 15
        : isTablet
        ? 17
        : 19;
    final double avatarRadius = isMobile
        ? 18
        : isTablet
        ? 22
        : 24;

    final bool showGreeting = width >= 380;
    final String greeting = _getGreeting();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF2b2b2b),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Info del usuario
            Expanded(
              child: Row(
                children: [
                  // Avatar con animacion de tap
                  GestureDetector(
                    key: _avatarKey,
                    onTap: _toggleMenu,
                    child: AnimatedScale(
                      scale: _isMenuOpen ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: _buildAvatar(radius: avatarRadius),
                    ),
                  ),
                  SizedBox(width: spacing),

                  // Textos
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showGreeting)
                          Text(
                            greeting,
                            style: GoogleFonts.poppins(
                              fontSize: greetingFontSize,
                              color: Colors.white60,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        Text(
                          widget.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Boton de notificaciones (opcional)
            if (widget.notificationCount > 0) ...[
              _buildNotificationButton(),
              SizedBox(width: spacing),
            ],

            // Indicador de menu abierto
            AnimatedRotation(
              turns: _isMenuOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            // Accion de notificaciones
          },
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.white.withOpacity(0.8),
            size: 24,
          ),
        ),
        if (widget.notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                widget.notificationCount > 99
                    ? '99+'
                    : widget.notificationCount.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos dias';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _confirmarLogout(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFF363636),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar sesion',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Estas seguro que deseas cerrar tu sesion? Tendras que volver a iniciar sesion para acceder.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Session.clear();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Cerrar sesion',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initialsFromName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    final first = parts[0];
    final second = parts.length > 1 ? parts[1] : '';

    final i1 = first.substring(0, 1).toUpperCase();
    final i2 = second.isNotEmpty ? second.substring(0, 1).toUpperCase() : '';

    return (i1 + i2).trim();
  }
}
