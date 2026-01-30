import 'package:expositor_app/core/constants/app_colors.dart';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/home/home_admin_page.dart';
import 'presentation/pages/home/home_user_page.dart';
import 'core/services/secure_storage_service.dart';
import 'data/models/vendedor.dart';
import 'data/services/vendedor_service.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Cargar Session desde storage
  await AuthService.hydrateSession();
  Widget initialPage = const LoginPage();

  //Decidir esta logged
  if (Session.isLoggedIn) {
    if (Session.isAdmin) {
      initialPage = const HomeAdminPage();
    } else {
      initialPage = const HomeUserPage();
    }
  } else {
    // (opcional) si quieres limpiar por seguridad
    final storage = SecureStorageService();
    await storage.clearAll();
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
      navigatorKey: navigatorKey,
    );
  }
}
