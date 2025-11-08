import 'package:flutter/material.dart';
import 'package:expositor_app/core/constants/app_colors.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController newPass = TextEditingController();
  final TextEditingController confirmPass = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.WHITE_BACKGROUND2,
      body: AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: 'Cambiar contraseña',
              subtitle: 'Ingrese y confirme su nueva contraseña.',
              icon: Icons.lock_reset_outlined,
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: newPass,
              label: 'Nueva contraseña',
              obscure: _obscure1,
              suffix: IconButton(
                icon: Icon(
                  _obscure1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: confirmPass,
              label: 'Confirmar contraseña',
              obscure: _obscure2,
              suffix: IconButton(
                icon: Icon(
                  _obscure2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
            const SizedBox(height: 16),
            AuthButton(
              text: 'Guardar nueva contraseña',
              onPressed: () {
                Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
