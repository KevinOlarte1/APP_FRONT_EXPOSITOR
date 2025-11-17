import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomFooter({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = screenHeight * 0.04; // Proporcional al alto de pantalla

    const activeColor = Color(0xFF3C75EF);
    const inactiveColor = Colors.black54;

    Widget buildSection({
      required IconData icon,
      required String label,
      required int index,
    }) {
      final isSelected = selectedIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isSelected ? activeColor : inactiveColor,
              ),
              SizedBox(height: screenHeight * 0.008),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: screenHeight * 0.018,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      // 👈 evita solaparse con el borde inferior
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildSection(icon: Icons.home, label: "Inicio", index: 0),
            _buildDivider(screenHeight),
            buildSection(
              icon: Icons.shopping_bag,
              label: "Productos",
              index: 1,
            ),
            _buildDivider(screenHeight),
            buildSection(
              icon: Icons.settings,
              label: "Configuración",
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double height) =>
      Container(width: 1, height: height * 0.05, color: Colors.grey.shade300);
}
