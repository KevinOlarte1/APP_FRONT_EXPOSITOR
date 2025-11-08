import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/core/constants/app_colors.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'recover_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.WHITE_BACKGROUND2,
      body: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: '¡Bienvenido!',
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

            AuthButton(text: 'Iniciar sesión', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
