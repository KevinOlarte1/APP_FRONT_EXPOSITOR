import 'package:flutter/material.dart';
import 'package:expositor_app/core/constants/app_colors.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'change_password_page.dart';

class VerificationCodePage extends StatelessWidget {
  const VerificationCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.WHITE_BACKGROUND2,
      body: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: 'Verificación',
              subtitle: 'Ingrese el código de 6 dígitos enviado a su correo.',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: codeController,
              label: 'Código de verificación',
            ),
            const SizedBox(height: 16),
            AuthButton(
              text: 'Verificar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
