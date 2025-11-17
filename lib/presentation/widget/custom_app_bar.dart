import 'package:expositor_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String avatarUrl;

  const CustomAppBar({super.key, required this.name, required this.avatarUrl});

  // Altura fija del AppBar (soluciona el overflow)
  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Breakpoints
    const double mobileMax = 600;
    const double tabletMax = 1024;

    final bool isMobile = width < mobileMax;
    final bool isTablet = width >= mobileMax && width < tabletMax;
    final bool isDesktop = width >= tabletMax;

    // Responsive metrics
    final double horizontalPadding = isMobile
        ? 16
        : isTablet
        ? 24
        : 32;
    final double avatarRadius = isMobile
        ? 16
        : isTablet
        ? 20
        : 24;
    final double spacing = isMobile
        ? 8
        : isTablet
        ? 12
        : 16;
    final double greetingFontSize = isMobile
        ? 12
        : isTablet
        ? 13
        : 14;
    final double nameFontSize = isMobile
        ? 16
        : isTablet
        ? 18
        : 20;
    final double iconSize = isMobile
        ? 22
        : isTablet
        ? 26
        : 30;

    final bool showGreeting = width >= 380;
    final String initials = _initialsFromName(name);
    final bool hasAvatar = avatarUrl.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: const BoxDecoration(color: Color(0xFF2b2b2b)),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // IZQUIERDA: avatar + textos
          Padding(
            padding: EdgeInsets.only(right: iconSize + spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.grey.shade700,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          initials,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: nameFontSize - 4,
                          ),
                        ),
                ),

                SizedBox(width: spacing),

                // Nombre + saludo
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGreeting)
                      Text(
                        '¡Hola, Bienvenido!',
                        style: GoogleFonts.poppins(
                          fontSize: greetingFontSize,
                          color: AppColors.GRAY_FONT,
                        ),
                      ),
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extrae iniciales del nombre
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
