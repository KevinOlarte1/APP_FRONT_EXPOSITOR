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
    return Scaffold(
      backgroundColor: AppColors.WHITE_BACKGROUND2,
      body: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: 'Recuperar contraseña',
              subtitle: 'Ingrese su correo para recibir el código.',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: emailController,
              label: 'Correo electrónico',
            ),
            const SizedBox(height: 16),
            AuthButton(
              text: 'Enviar código',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationCodePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
