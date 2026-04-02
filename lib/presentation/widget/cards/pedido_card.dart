import 'package:flutter/material.dart';
import 'package:expositor_app/data/models/pedido.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const PedidoCard({super.key, required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool cerrado = pedido.cerrado;
    final int numLineas = pedido.idLineaPedido.length;

    final accent = cerrado ? Colors.green : Colors.orange;
    final accentSoft = accent.withOpacity(0.14);

    final comentario = pedido.comentario.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IntrinsicHeight(
            // ✅ hace que el Row adopte el alto del contenido
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // ✅ estira hijos verticalmente
              children: [
                // Accent lateral (sin altura fija)
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // ✅ no fuerces height
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusBadge(
                              cerrado: cerrado,
                              accent: accent,
                              accentSoft: accentSoft,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Pedido #${pedido.id}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.35),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pedido.fecha.isNotEmpty
                                        ? pedido.fecha
                                        : "Sin fecha",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              icon: Icons.format_list_bulleted_rounded,
                              text: "$numLineas líneas",
                            ),
                            _Chip(
                              icon: Icons.receipt_long_rounded,
                              text: "Bruto ${pedido.brutoTotal}€",
                            ),
                            _Chip(
                              icon: Icons.percent_rounded,
                              text: "IVA ${pedido.iva}%",
                            ),
                            if (pedido.descuento != 0)
                              _Chip(
                                icon: Icons.local_offer_rounded,
                                text: "DTO ${pedido.descuento}%",
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Total + Base (responsive)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: accentSoft,
                            border: Border.all(color: accent.withOpacity(0.22)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "TOTAL",
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.60),
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      // ✅ evita overflow si el total es largo
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "${pedido.total}€",
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 92,
                                  maxWidth: 140,
                                ),
                                child: _MiniBlock(
                                  label: "Base",
                                  value: "${pedido.baseImponible}€",
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Comentario
                        if (comentario.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.45),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.55),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comentario,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.75),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool cerrado;
  final Color accent;
  final Color accentSoft;

  const _StatusBadge({
    required this.cerrado,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final text = cerrado ? "CERRADO" : "ABIERTO";
    final icon = cerrado ? Icons.lock_rounded : Icons.edit_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MiniBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
