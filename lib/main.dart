import 'package:expositor_app/core/constants/app_colors.dart';
import 'package:expositor_app/core/navigation/navigator_key.dart';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/home/home_admin_page.dart';
import 'presentation/pages/home/home_user_page.dart';
import 'core/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialPage = await _resolveInitialPage();
  runApp(MyApp(initialPage: initialPage));
}

Future<Widget> _resolveInitialPage() async {
  try {
    await AuthService.hydrateSession();
    if (Session.isLoggedIn) {
      return Session.isAdmin ? const HomeAdminPage() : const HomeUserPage();
    }
    await SecureStorageService().clearAll();
  } catch (e, stackTrace) {
    debugPrint('[main] Error al hidratar sesión: $e');
    debugPrint(stackTrace.toString());
    Session.clear();
  }
  return const LoginPage();
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expositor App',
      // Material 3 desactivado para mantener consistencia con el diseño actual
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
