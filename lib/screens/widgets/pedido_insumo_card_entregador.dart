import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido_insumo_model.dart';
import 'detalhes_pedido_insumo_entregador_modal.dart';

class PedidoInsumoCardEntregador extends StatelessWidget {
  final PedidoInsumoModel item;
  final bool isFinalizados;

  const PedidoInsumoCardEntregador({
    super.key,
    required this.item,
    required this.isFinalizados,
  });

  String _obterTurno(DateTime? data) {
    if (data == null) return '';
    final hora = data.hour;
    if (hora >= 5 && hora < 12) return 'Manhã';
    if (hora >= 12 && hora < 18) return 'Tarde';
    return 'Noite';
  }

  @override
  Widget build(BuildContext context) {
    final formatadorHora = DateFormat('HH:mm');
    const Color corTema = Color(0xFF34C759); // Verde padrão para insumos

    final String statusNorm = item.status.toLowerCase();

    // Configuração de cores e textos do Badge baseados no próprio model
    Color bgBadge = item.corStatus.withOpacity(0.12);
    Color fgBadge = item.corStatus;

    final String turnoText = _obterTurno(item.dataSolicitacao);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: corTema.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: corTema,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'PEDIDO DE INSUMO',
                            style: TextStyle(
                              color: corTema,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${item.id.substring(0, 8)}...',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Origem (Laboratório)
                      Text(
                        item.nomeOrigemVisual,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1C1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Destino (Clínica)
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.nomeDestinoVisual,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bgBadge,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.textoStatus,
                        style: TextStyle(
                          color: fgBadge,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (turnoText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              turnoText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF636366),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          formatadorHora.format(item.dataSolicitacao),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (!isFinalizados) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF2F2F7)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => DetalhesPedidoInsumoEntregadorModal.exibir(
                      context,
                      item,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F7),
                      foregroundColor: const Color(0xFF34C759),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Detalhes",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
