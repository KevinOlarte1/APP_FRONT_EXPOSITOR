import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/services/vendedor_service.dart';
import 'package:expositor_app/data/services/parametros_globales_service.dart';

class ConfigVendedorPage extends StatefulWidget {
  final Vendedor vendedorActual;

  const ConfigVendedorPage({super.key, required this.vendedorActual});

  @override
  State<ConfigVendedorPage> createState() => _ConfigVendedorPageState();
}

class _ConfigVendedorPageState extends State<ConfigVendedorPage> {
  final VendedorService _vendedorService = VendedorService();
  final ParametrosGlobalesService _paramService = ParametrosGlobalesService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  late final TextEditingController _ivaCtrl;
  late final TextEditingController _descuentoCtrl;

  bool _savingProfile = false;
  bool _savingPedidoConfig = false;
  bool _loadingPedidoConfig = true;

  @override
  void initState() {
    super.initState();

    _nombreCtrl = TextEditingController(text: widget.vendedorActual.nombre);
    _apellidoCtrl = TextEditingController(text: widget.vendedorActual.apellido);
    _emailCtrl = TextEditingController(text: widget.vendedorActual.email);
    _passwordCtrl = TextEditingController();

    _ivaCtrl = TextEditingController();
    _descuentoCtrl = TextEditingController();

    _loadPedidoConfig();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ivaCtrl.dispose();
    _descuentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPedidoConfig() async {
    try {
      final cfg = await _paramService.getParams();

      _ivaCtrl.text = (cfg['iva'] ?? '').toString();
      _descuentoCtrl.text = (cfg['descuento'] ?? '').toString();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar la configuración de pedidos.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingPedidoConfig = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);

    try {
      final updated = Vendedor(
        id: widget.vendedorActual.id,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: widget.vendedorActual.role,
      );

      final success = await _vendedorService.updateVendedor(
        updated,
        password: _passwordCtrl.text.trim().isEmpty
            ? null
            : _passwordCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Datos del vendedor actualizados correctamente.'
                : 'No se pudo actualizar el perfil.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _passwordCtrl.clear();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar los datos del vendedor.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _savePedidoConfig() async {
    final iva = double.tryParse(_ivaCtrl.text.trim());
    final descuento = double.tryParse(_descuentoCtrl.text.trim());

    if (iva == null || descuento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IVA y descuento deben ser valores numéricos.'),
        ),
      );
      return;
    }

    if (iva < 0 || iva > 100 || descuento < 0 || descuento > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IVA y descuento deben estar entre 0 y 100.'),
        ),
      );
      return;
    }

    setState(() => _savingPedidoConfig = true);

    try {
      final ok = await _paramService.saveParams(
        iva: iva,
        descuento: descuento,
        grupoMax: 1,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Configuración de pedidos guardada.'
                : 'No se pudo guardar la configuración.',
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar la configuración.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPedidoConfig = false);
      }
    }
  }

  double get _previewSubtotal => 100.0;

  double get _previewIva {
    final iva = double.tryParse(_ivaCtrl.text.trim()) ?? 0;
    return (_previewSubtotal * iva) / 100;
  }

  double get _previewDescuento {
    final descuento = double.tryParse(_descuentoCtrl.text.trim()) ?? 0;
    return (_previewSubtotal * descuento) / 100;
  }

  double get _previewTotal =>
      _previewSubtotal + _previewIva - _previewDescuento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                _SectionCard(
                  icon: Icons.person_outline,
                  iconText: 'V',
                  title: 'Datos del vendedor',
                  subtitle:
                      'Administra tu información personal y tus credenciales de acceso.',
                  badgeText: 'Perfil activo',
                  child: Column(
                    children: [
                      _ResponsiveTwoColumns(
                        children: [
                          _ConfigTextField(
                            label: 'Nombre',
                            controller: _nombreCtrl,
                            hint: 'Nombre',
                          ),
                          _ConfigTextField(
                            label: 'Apellido',
                            controller: _apellidoCtrl,
                            hint: 'Apellido',
                          ),
                          _ConfigTextField(
                            label: 'Correo electrónico',
                            controller: _emailCtrl,
                            hint: 'correo@empresa.com',
                            keyboardType: TextInputType.emailAddress,
                            fullWidth: true,
                          ),
                          _ConfigTextField(
                            label: 'Nueva contraseña',
                            controller: _passwordCtrl,
                            hint: '********',
                            obscureText: true,
                            fullWidth: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CardFooter(
                        infoText:
                            'Actualiza solo los datos que quieras cambiar.',
                        primaryLabel: 'Guardar cambios',
                        secondaryLabel: 'Cancelar',
                        onSecondaryTap: () {
                          _nombreCtrl.text = widget.vendedorActual.nombre;
                          _apellidoCtrl.text = widget.vendedorActual.apellido;
                          _emailCtrl.text = widget.vendedorActual.email;
                          _passwordCtrl.clear();
                          setState(() {});
                        },
                        onPrimaryTap: _savingProfile ? null : _saveProfile,
                        loading: _savingProfile,
                      ),
                    ],
                  ),
                ),

                if (Session.isAdmin) ...[
                  const SizedBox(height: 24),
                  _SectionCard(
                    icon: Icons.receipt_long_outlined,
                    iconText: 'P',
                    title: 'Configuración de pedidos',
                    subtitle:
                        'Define el IVA y el descuento por defecto para pedidos nuevos.',
                    badgeText: 'Activo',
                    child: _loadingPedidoConfig
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Column(
                            children: [
                              _ResponsiveTwoColumns(
                                children: [
                                  _ConfigTextField(
                                    label: 'IVA (%)',
                                    controller: _ivaCtrl,
                                    hint: '21',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  _ConfigTextField(
                                    label: 'Descuento (%)',
                                    controller: _descuentoCtrl,
                                    hint: '10',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _PreviewBox(
                                subtotal: _previewSubtotal,
                                iva: double.tryParse(_ivaCtrl.text.trim()) ?? 0,
                                descuento:
                                    double.tryParse(
                                      _descuentoCtrl.text.trim(),
                                    ) ??
                                    0,
                                ivaAmount: _previewIva,
                                descuentoAmount: _previewDescuento,
                                total: _previewTotal,
                              ),
                              const SizedBox(height: 10),
                              _CardFooter(
                                infoText:
                                    'Estos valores se aplicarán automáticamente a nuevos pedidos.',
                                primaryLabel: 'Guardar cambios',
                                secondaryLabel: 'Restablecer',
                                onSecondaryTap: () {
                                  _ivaCtrl.text = '21';
                                  _descuentoCtrl.text = '0';
                                  setState(() {});
                                },
                                onPrimaryTap: _savingPedidoConfig
                                    ? null
                                    : _savePedidoConfig,
                                loading: _savingPedidoConfig,
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String iconText;
  final String title;
  final String subtitle;
  final String badgeText;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconText,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  iconText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveTwoColumns extends StatelessWidget {
  final List<_ConfigTextField> children;

  const _ResponsiveTwoColumns({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 640;

        if (isSingleColumn) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        final rows = <Widget>[];
        int index = 0;

        while (index < children.length) {
          final current = children[index];

          if (current.fullWidth) {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: current,
              ),
            );
            index++;
            continue;
          }

          final next =
              (index + 1 < children.length && !children[index + 1].fullWidth)
              ? children[index + 1]
              : null;

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(child: current),
                  const SizedBox(width: 18),
                  Expanded(child: next ?? const SizedBox()),
                ],
              ),
            ),
          );

          index += next == null ? 1 : 2;
        }

        return Column(children: rows);
      },
    );
  }
}

class _ConfigTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final bool fullWidth;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _ConfigTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.fullWidth = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final double subtotal;
  final double iva;
  final double descuento;
  final double ivaAmount;
  final double descuentoAmount;
  final double total;

  const _PreviewBox({
    required this.subtotal,
    required this.iva,
    required this.descuento,
    required this.ivaAmount,
    required this.descuentoAmount,
    required this.total,
  });

  String _format(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista previa',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          _PreviewRow(label: 'Subtotal', value: '€${_format(subtotal)}'),
          const SizedBox(height: 8),
          _PreviewRow(
            label: 'IVA (${iva.toStringAsFixed(0)}%)',
            value: '+ €${_format(ivaAmount)}',
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: 'Descuento (${descuento.toStringAsFixed(0)}%)',
            value: '- €${_format(descuentoAmount)}',
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _PreviewRow(
            label: 'Total',
            value: '€${_format(total)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      fontSize: isTotal ? 15 : 14,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: isTotal ? const Color(0xFF111827) : const Color(0xFF374151),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: textStyle),
      ],
    );
  }
}

class _CardFooter extends StatelessWidget {
  final String infoText;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;
  final bool loading;

  const _CardFooter({
    required this.infoText,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  infoText,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onSecondaryTap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    secondaryLabel,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onPrimaryTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          primaryLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          }

          return Column(
            children: [
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      infoText,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: onSecondaryTap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(130, 46),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onPrimaryTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(170, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            primaryLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
