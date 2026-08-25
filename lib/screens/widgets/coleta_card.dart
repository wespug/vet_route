import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/screens/widgets/confirmar_recusa_dialog.dart';
import 'package:vet_route/screens/widgets/detalhes_coleta_modal.dart';
import '../../../../models/coleta_model.dart';

class ColetaCard extends StatelessWidget {
  final Coleta item;
  final bool isFinalizados;

  const ColetaCard({
    super.key,
    required this.item,
    required this.isFinalizados,
  });

  /// Calcula o turno baseado na hora do pedido
  String _obterTurno(DateTime? data) {
    if (data == null) return '';
    final hora = data.hour;
    if (hora >= 5 && hora < 12) {
      return 'Manhã';
    } else if (hora >= 12 && hora < 18) {
      return 'Tarde';
    } else {
      return 'Noite';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatadorHora = DateFormat('HH:mm');
    final bool isInsumo =
        item.codigo.startsWith('INS') ||
        (item.codigoAcompanhamento != null &&
            item.codigoAcompanhamento!.contains('INS'));

    final Color corTema = isInsumo
        ? const Color(0xFF34C759)
        : const Color(0xFF007AFF);

    // Resolução segura de Clínica e Laboratório
    final String nomeClinicaExibir = item.nomeClinica.trim().isNotEmpty
        ? item.nomeClinica
        : 'Clínica não informada';

    final String labNomeExibir = item.laboratorioDestino.nome.trim().isNotEmpty
        ? item.laboratorioDestino.nome
        : 'Laboratório não informado';

    final String statusNorm = item.status.toLowerCase();
    final bool isRecusado =
        statusNorm.contains('recusad') || statusNorm.contains('cancel');

    Color bgBadge = const Color(0xFFFF9500).withOpacity(0.12);
    Color fgBadge = const Color(0xFFFF9500);
    String statusTexto = 'Pendente';

    if (isRecusado) {
      bgBadge = const Color(0xFFFF3B30).withOpacity(0.12);
      fgBadge = const Color(0xFFFF3B30);
      statusTexto = 'Recusado';
    } else if (statusNorm.contains('conclu') ||
        statusNorm.contains('entregue')) {
      bgBadge = const Color(0xFF34C759).withOpacity(0.12);
      fgBadge = const Color(0xFF34C759);
      statusTexto = 'Concluído';
    } else if (statusNorm.contains('andamento') ||
        statusNorm.contains('rota')) {
      bgBadge = const Color(0xFF007AFF).withOpacity(0.12);
      fgBadge = const Color(0xFF007AFF);
      statusTexto = 'Em Rota';
    }

    final String turnoText = _obterTurno(item.dataCriacao);

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
                  child: Icon(
                    isInsumo
                        ? Icons.inventory_2_rounded
                        : Icons.two_wheeler_rounded,
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
                          Text(
                            isInsumo ? 'PEDIDO DE INSUMO' : 'COLETA DE EXAME',
                            style: TextStyle(
                              color: corTema,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (item.codigo.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•  ${item.codigo}',
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Nome da Clínica
                      Text(
                        nomeClinicaExibir,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1C1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Nome do Laboratório Destino
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
                              labNomeExibir,
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
                        statusTexto,
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
                        if (item.dataCriacao != null)
                          Text(
                            formatadorHora.format(item.dataCriacao!),
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
                  TextButton(
                    onPressed: () =>
                        ConfirmarRecusaDialog.exibir(context, item),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3B30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Recusar",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        DetalhesColetaModal.exibir(context, item, isInsumo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F7),
                      foregroundColor: const Color(0xFF007AFF),
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
