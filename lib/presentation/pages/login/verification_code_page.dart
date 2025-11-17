import 'package:expositor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:expositor_app/core/constants/app_colors.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'change_password_page.dart';

class VerificationCodePage extends StatelessWidget {
  final String email;

  const VerificationCodePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();
    final _authService = AuthService();

    void _onSendCode() {
      final code = codeController.text.trim();

      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor codigo valido')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChangePasswordPage(codeVerification: code, email: email),
        ),
      );
    }

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
            AuthButton(text: 'Verificar', onPressed: _onSendCode),
          ],
        ),
      ),
    );
  }
}
