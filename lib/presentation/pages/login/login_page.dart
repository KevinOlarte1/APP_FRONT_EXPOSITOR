import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/session/session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/core/constants/app_colors.dart';

import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';

import 'recover_password_page.dart';

import 'package:expositor_app/data/dto/login_request.dart';
import 'package:expositor_app/data/services/auth_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';

import '../home/home_admin_page.dart';
import '../home/home_user_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final VendedorService _vendedorService = VendedorService();
  bool _obscure = true;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final loginRequest = LoginRequest(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final response = await _authService.login(loginRequest);

    setState(() => _isLoading = false);

    if (response != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              Session.isAdmin ? const HomeAdminPage() : const HomeUserPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiConstants.msgtmp)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.WHITE_BACKGROUND2,
      body: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: '¡Bienvienido!',
              subtitle: 'Por favor ingrese sus credenciales.',
            ),
            const SizedBox(height: 32),

            AuthTextField(
              controller: emailController,
              label: 'Correo electrónico',
            ),
            const SizedBox(height: 16),

            AuthTextField(
              controller: passwordController,
              label: 'Contraseña',
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecoverPasswordPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.BLUE_BACKGROUND,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            AuthButton(text: 'Iniciar sesión', onPressed: _login),
          ],
        ),
      ),
    );
  }
}
