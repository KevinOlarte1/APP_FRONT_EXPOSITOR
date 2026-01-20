import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/presentation/pages/admin/cliente/cliente_admin_page.dart';
import 'package:expositor_app/presentation/pages/admin/dashboard_admin_page.dart';
import 'package:expositor_app/presentation/pages/admin/config/config_vendedor_admin_page.dart';
import 'package:expositor_app/presentation/widget/custom_app_bar.dart';
import 'package:expositor_app/presentation/widget/custom_footer.dart';
import 'package:flutter/material.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  final VendedorService _vendedorService = VendedorService();

  Vendedor? _vendedorActual;
  bool _loading = true;
  bool _error = false;

  int _selectedIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final vendedor = await _vendedorService.getMe();

    if (!mounted) return;

    if (vendedor == null) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }

    setState(() {
      _vendedorActual = vendedor;
      _pages
        ..clear()
        ..addAll([
          VendedoresDashboardPage(),
          ClientesPage(),
          ConfigVendedorPage(vendedorActual: vendedor),
        ]);
      _loading = false;
      _error = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error
    if (_error || _vendedorActual == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 12),
                const Text(
                  "No se pudo cargar tu perfil.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadMe,
                  child: const Text("Reintentar"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final vendedor = _vendedorActual!;
    final name = "${vendedor.nombre} ${vendedor.apellido}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: CustomAppBar(
          name: name,
          avatarUrl: 'https://cdn.pfps.gg/pfps/2903-default-blue.png',
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomFooter(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
