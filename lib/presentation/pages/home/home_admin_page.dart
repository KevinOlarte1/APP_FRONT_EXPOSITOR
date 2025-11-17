import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expositor_app/presentation/widget/custom_app_bar.dart';
import 'package:expositor_app/presentation/widget/custom_footer.dart';
import 'package:expositor_app/presentation/pages/admin/product_admin_page.dart';
import 'package:expositor_app/presentation/pages/admin/dashboard_admin_page.dart';

class HomeAdminPage extends StatefulWidget {
  final String nombre;
  final String email;

  const HomeAdminPage({super.key, required this.nombre, required this.email});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      VendedoresDashboardPage(),
      ProductAdminPage(),
      Center(
        child: Text(
          'Configuración del sistema',
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: CustomAppBar(
          name: widget.nombre,
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
