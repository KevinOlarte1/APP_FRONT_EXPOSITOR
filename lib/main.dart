import 'package:expositor_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/home/home_admin_page.dart';
import 'presentation/pages/home/home_user_page.dart';
import 'core/services/secure_storage_service.dart';
import 'data/models/vendedor.dart';
import 'data/services/vendedor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  final token = await storage.getAccessToken();
  Widget initialPage = const LoginPage();
  if (token != null) {
    final vendedorService = VendedorService();
    final Vendedor? vendedor = await vendedorService.getMe();

    if (vendedor != null) {
      if (vendedor.role.toUpperCase().contains("ADMIN")) {
        initialPage = HomeAdminPage(vendedorActual: vendedor);
      } else {
        initialPage = HomeUserPage(vendedorActual: vendedor);
      }
    } else {
      // Token inválido o expirado → limpiamos
      await storage.clearTokens();
    }
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expositor App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.BLUE_BACKGROUND),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: false,
      ),
      home: initialPage,
    );
  }
}
