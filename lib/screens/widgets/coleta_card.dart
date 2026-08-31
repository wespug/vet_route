import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/screens/web/entregadores/components/modal_detalhes_coleta_motoboy.dart';

class ColetaCard extends StatelessWidget {
  final Coleta item;
  final bool isFinalizados;

  const ColetaCard({
    super.key,
    required this.item,
    required this.isFinalizados,
  });

  @override
  Widget build(BuildContext context) {
    final String horaFormatada = item.dataCriacao != null
        ? "${item.dataCriacao!.hour.toString().padLeft(2, '0')}:${item.dataCriacao!.minute.toString().padLeft(2, '0')}"
        : '--:--';

    // 💡 CORREÇÃO: Removido o item.isInsumo inexistente. Baseado apenas na regra de string.
    final bool isInsumo =
        item.codigo.toUpperCase().contains('INS') ||
        (item.codigoAcompanhamento?.toUpperCase().contains('INS') ?? false);

    final String labNome = item.laboratorioDestino.nome.isNotEmpty
        ? item.laboratorioDestino.nome
        : 'Laboratório Parceiro';

    final String statusNorm = item.status.toLowerCase();
    final bool isRecusado =
        statusNorm.contains('recusad') || statusNorm.contains('cancel');

    final String localOrigem = isInsumo ? labNome : item.nomeClinica;
    final String localDestino = isInsumo ? item.nomeClinica : labNome;

    final String codigoOriginal = item.codigo.isNotEmpty
        ? item.codigo
        : (item.codigoAcompanhamento ?? item.id);
    final String codigoFormatado = codigoOriginal.length >= 6
        ? codigoOriginal.substring(0, 6).toUpperCase()
        : codigoOriginal.toUpperCase();

    Color corBadge;
    Color corFundoBadge;
    String statusTexto;

    if (isRecusado) {
      corBadge = const Color(0xFFE53935);
      corFundoBadge = const Color(0xFFFFEBEE);
      statusTexto = 'Recusada / Cancelada';
    } else if (isFinalizados) {
      corBadge = const Color(0xFF43A047);
      corFundoBadge = const Color(0xFFE8F5E9);
      statusTexto = 'Concluída';
    } else if (statusNorm.contains('rota') || statusNorm.contains('caminho')) {
      corBadge = Colors.orange.shade800;
      corFundoBadge = Colors.orange.shade50;
      statusTexto = 'Em Rota';
    } else {
      corBadge = Colors.indigo;
      corFundoBadge = Colors.indigo.shade50;
      statusTexto = 'Nova Parada';
    }

    return Opacity(
      opacity: isFinalizados ? 0.65 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: isFinalizados
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: corFundoBadge,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusTexto.toUpperCase(),
                      style: TextStyle(
                        color: corBadge,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    horaFormatada,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1.5),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        color: isInsumo
                            ? const Color(0xFF34C759)
                            : const Color(0xFF007AFF),
                        size: 18,
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Coletar em",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          localOrigem,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Entregar em",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          localDestino,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isInsumo
                                ? Icons.inventory_2_rounded
                                : Icons.vaccines_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${isInsumo ? 'Insumo' : 'Exame'} • ID: #$codigoFormatado",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ModalDetalhesColetaMotoboy(
                              item: item,
                              isInsumo: isInsumo,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            "Ver Detalhes",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!isFinalizados) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => _confirmarRecusa(context, item),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                color: Colors.redAccent.shade100,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Recusar",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Ação de iniciar rota em desenvolvimento.",
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Iniciar Rota",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarRecusa(BuildContext context, Coleta item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Recusar Parada",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          "Tem certeza que deseja recusar esta parada? Ela voltará para a fila de atribuição do laboratório.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = Provider.of<ColetaController>(
                context,
                listen: false,
              );
              await controller.recusarColeta(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Sim, Recusar"),
          ),
        ],
      ),
    );
  }
}
