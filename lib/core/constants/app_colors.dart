import 'package:flutter/material.dart';

/// Clase de colores centralizada para la aplicacion
/// Sigue el patron de design tokens para consistencia visual
class AppColors {
  AppColors._();

  static const Color WHITE_BACKGROUND = Color(0xFFF5F5F5);
  static const Color WHITE_BACKGROUND2 = Color(0xFFF8FAFC);
  static const Color BLACK_BACKGROUND = Color(0xFF2b2b2b);
  static const Color BLUE_BACKGROUND = Color(0XFF3C75EF);
  static const Color RED_BACKGROUND = Color(0xFF2A1D1D);

  static const Color WHITE_COLOR = Color(0x00FFFFFF);

  static const Color GRAY_FONT = Color(0xB3FFFFFF);
  static const Color RED_FONT = Color(0xFFFF5963);
  static const Color GREEN_FONT = Color(0xFF2ECC71);
  static const Color BLACK_FONT = Color(0xDE000000);

  // ============================================
  // COLORES PRIMARIOS
  // ============================================

  /// Color primario principal - usado en botones, links activos, elementos destacados
  static const Color primary = Color(0xFF2563EB); // Blue 600

  /// Variante clara del primario - para backgrounds suaves, hovers
  static const Color primaryLight = Color(0xFFDBEAFE); // Blue 100

  /// Variante oscura del primario - para estados pressed, textos sobre primary
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700

  // ============================================
  // COLORES DE SUPERFICIE / FONDO
  // ============================================

  /// Fondo principal de la app
  static const Color background = Color(0xFFF8FAFC); // Slate 50

  /// Superficie de cards, modals, elementos elevados
  static const Color surface = Color(0xFFFFFFFF); // White

  /// Superficie secundaria - para secciones diferenciadas
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100

  /// Borde por defecto
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  /// Borde sutil - para divisores menos prominentes
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100

  // ============================================
  // COLORES DE TEXTO
  // ============================================

  /// Texto principal - titulos, contenido importante
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900

  /// Texto secundario - descripciones, labels
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  /// Texto terciario - placeholders, texto deshabilitado
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  /// Texto invertido - sobre fondos oscuros
  static const Color textInverse = Color(0xFFFFFFFF); // White

  // ============================================
  // COLORES SEMANTICOS - ESTADOS
  // ============================================

  /// Exito - confirmaciones, completado, activo
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color successLight = Color(0xFFDCFCE7); // Green 100
  static const Color successDark = Color(0xFF16A34A); // Green 600

  /// Advertencia - alertas, atencion requerida
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningDark = Color(0xFFD97706); // Amber 600

  /// Error - errores, eliminacion, peligro
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color errorDark = Color(0xFFDC2626); // Red 600

  /// Info - informacion, ayuda
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100
  static const Color infoDark = Color(0xFF2563EB); // Blue 600

  // ============================================
  // COLORES DE NAVEGACION
  // ============================================

  /// Item de navegacion activo
  static const Color navActive = primary;

  /// Item de navegacion inactivo
  static const Color navInactive = Color(0xFF64748B); // Slate 500

  /// Fondo de item activo en sidebar
  static const Color navActiveBackground = Color(0xFFEFF6FF); // Blue 50

  // ============================================
  // COLORES ESPECIALES
  // ============================================

  /// Overlay para modals, drawers
  static const Color overlay = Color(0x80000000); // Black 50%

  /// Shimmer base - para loading skeletons
  static const Color shimmerBase = Color(0xFFE2E8F0); // Slate 200

  /// Shimmer highlight - para animacion de loading
  static const Color shimmerHighlight = Color(0xFFF8FAFC); // Slate 50

  /// Divider - lineas separadoras
  static const Color divider = Color(0xFFE2E8F0); // Slate 200

  // ============================================
  // GRADIENTES
  // ============================================

  /// Gradiente primario - para botones destacados, headers
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // Blue 500
      Color(0xFF2563EB), // Blue 600
    ],
  );

  /// Gradiente de superficie - para cards con profundidad
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // ============================================
  // SOMBRAS
  // ============================================

  /// Sombra pequena - para botones, inputs
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Sombra mediana - para cards, dropdowns
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra grande - para modals, popovers
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Sombra extra grande - para elementos flotantes
  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // ============================================
  // METODOS UTILES
  // ============================================

  /// Retorna el color de estado segun el tipo
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
      case 'online':
        return success;
      case 'warning':
      case 'pending':
      case 'processing':
        return warning;
      case 'error':
      case 'failed':
      case 'offline':
      case 'inactive':
        return error;
      case 'info':
      default:
        return info;
    }
  }

  /// Retorna el color de fondo claro segun el estado
  static Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
      case 'online':
        return successLight;
      case 'warning':
      case 'pending':
      case 'processing':
        return warningLight;
      case 'error':
      case 'failed':
      case 'offline':
      case 'inactive':
        return errorLight;
      case 'info':
      default:
        return infoLight;
    }
  }

  /// Color con opacidad personalizada
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

/// Extension para facilitar el uso de colores con opacidad
extension ColorOpacity on Color {
  Color get o10 => withOpacity(0.1);
  Color get o20 => withOpacity(0.2);
  Color get o30 => withOpacity(0.3);
  Color get o40 => withOpacity(0.4);
  Color get o50 => withOpacity(0.5);
  Color get o60 => withOpacity(0.6);
  Color get o70 => withOpacity(0.7);
  Color get o80 => withOpacity(0.8);
  Color get o90 => withOpacity(0.9);
}
