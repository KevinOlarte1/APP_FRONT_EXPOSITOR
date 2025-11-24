import 'package:expositor_app/data/services/auth_service.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:flutter/material.dart';
import 'package:expositor_app/core/constants/app_colors.dart';
import '../../../data/dto/login_request.dart';
import '../../../data/dto/login_response.dart';

import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'login_page.dart';
import '../home/home_admin_page.dart';
import '../home/home_user_page.dart';

class ChangePasswordPage extends StatefulWidget {
  final String email;
  final String codeVerification;
  const ChangePasswordPage({
    super.key,
    required this.codeVerification,
    required this.email,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController newPass = TextEditingController();
  final TextEditingController confirmPass = TextEditingController();
  final _authService = AuthService();
  final _vendedorService = VendedorService();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  void _OnPasswordSended() async {
    final newPassword = newPass.text.trim();
    final confirmPassword = confirmPass.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese algo en los campos')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deben coincidir los campos.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    // 🔹 1. Llamar al endpoint de reset password
    final success = await _authService.resetPassword(
      email: widget.email,
      code: widget.codeVerification,
      newPassword: newPassword,
    );
    if (success) {
      // 🔹 2. Intentar login automáticamente
      final loginResponse = await _authService.login(
        LoginRequest(email: widget.email, password: newPassword),
      );

      if (loginResponse != null) {
        // 🔹 3. Obtener datos del vendedor
        final vendedor = await _vendedorService.getMe();

        setState(() => _isLoading = false);

        if (vendedor == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al obtener el perfil')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
          return;
        }

        // 🔹 4. Redirigir según rol
        if (vendedor.role.toUpperCase().contains("ADMIN")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeAdminPage(vendedorActual: vendedor),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeUserPage(vendedorActual: vendedor),
            ),
            (route) => false,
          );
        }
      } else {
        // ❌ Si el login falla, volver al login
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar sesión automáticamente'),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al restablecer la contraseña')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
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
              onPressed: _OnPasswordSended,
            ),
          ],
        ),
      ),
    );
  }
}
