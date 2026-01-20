import 'package:expositor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:expositor_app/core/constants/app_colors.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'verification_code_page.dart';

class RecoverPasswordPage extends StatelessWidget {
  const RecoverPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final _authService = AuthService();

    void _onSendCode() async {
      final String email = emailController.text.trim().toLowerCase();
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      if (email.isEmpty || !emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingrese un correo válido')),
        );
        return;
      }

      final success = await _authService.forgotPassword(email);
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerificationCodePage(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar el correo de recuperación'),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.WHITE_BACKGROUND2,
      body: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: 'Recuperar 2 contraseña',
              subtitle: 'Ingrese su correo para recibir el código.',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: emailController,
              label: 'Correo electrónico',
            ),
            const SizedBox(height: 16),
            AuthButton(text: 'Enviar código', onPressed: _onSendCode),
          ],
        ),
      ),
    );
  }
}
