import 'package:flutter/material.dart';
import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';

class ModalDetalhesInsumo extends StatelessWidget {
  final ChamadoColetaModel chamado;
  final Clinica clinicaContexto;
  final String usuarioLogado;
  final Color Function(String) obterCorStatus;

  final PedidoInsumoController _controller = PedidoInsumoController();

  ModalDetalhesInsumo({
    super.key,
    required this.chamado,
    required this.clinicaContexto,
    required this.usuarioLogado,
    required this.obterCorStatus,
  });

  Future<void> _solicitarCancelamento(
    BuildContext context,
    String docIdLimpo,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancelar Pedido de Insumos?"),
        content: const Text(
          "Tem certeza de que deseja cancelar esta solicitação? Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Voltar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmar Cancelamento"),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      try {
        await _controller.cancelarPedido(
          docIdLimpo: docIdLimpo,
          chamadoIdOriginal: chamado.id,
          usuarioLogado: usuarioLogado,
        );

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pedido de insumos cancelado com sucesso."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao cancelar o pedido: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docIdLimpo = chamado.id.replaceFirst('INSUMO_', '');

    return StreamBuilder<PedidoInsumoModel?>(
      stream: _controller.obterStreamPedido(docIdLimpo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
          );
        }

        final pedido = snapshot.data;

        if (pedido == null) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Não foi possível localizar os dados deste pedido de insumos.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fechar"),
              ),
            ],
          );
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: Colors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Insumos - ${chamado.laboratorioNome}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. HEADER DE STATUS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: pedido.corStatus.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pedido.corStatus.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pedido.iconeStatus,
                          color: pedido.corStatus,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pedido.textoStatus,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pedido.corStatus,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "Solicitado em: ${pedido.formatarData(pedido.dataSolicitacao ?? chamado.dataCriacao)}",
                                    ),
                                    const TextSpan(text: " por "),
                                    TextSpan(
                                      text: pedido.usuarioSolicitante,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. ALERTA DE OBSERVAÇÃO / RECUSA
                  if (pedido.justificativaLab.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: pedido.isRecusadoOuCancelado
                            ? Colors.red.shade50
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: pedido.isRecusadoOuCancelado
                              ? Colors.red.shade300
                              : Colors.amber.shade400,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pedido.isRecusadoOuCancelado
                                    ? Icons.error_outline
                                    : Icons.info_outline,
                                color: pedido.isRecusadoOuCancelado
                                    ? Colors.red.shade700
                                    : Colors.amber.shade900,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pedido.isRecusadoOuCancelado
                                    ? "Motivo do Cancelamento / Recusa:"
                                    : "Observação do Laboratório:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pedido.isRecusadoOuCancelado
                                      ? Colors.red.shade700
                                      : Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pedido.justificativaLab,
                            style: TextStyle(
                              color: pedido.isRecusadoOuCancelado
                                  ? Colors.red.shade900
                                  : Colors.black87,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          if (pedido.usuarioLabObs.isNotEmpty ||
                              pedido.dataLabObs != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Por: ${pedido.usuarioLabObs.isNotEmpty ? pedido.usuarioLabObs : 'Laboratório'}" +
                                    (pedido.dataLabObs != null
                                        ? " em ${pedido.formatarData(pedido.dataLabObs)}"
                                        : ""),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: pedido.isRecusadoOuCancelado
                                      ? Colors.red.shade800
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. MATERIAIS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Materiais Solicitados:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${pedido.itens.length} tipo(s)",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pedido.itens.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = pedido.itens[index];
                        final nomeInsumo =
                            item['descricao'] ??
                            item['nomeInsumo'] ??
                            item['nome'] ??
                            'Insumo';
                        final qtd =
                            item['quantidade'] ??
                            item['quantidadeSolicitada'] ??
                            item['qtd'] ??
                            0;
                        final tipo = item['tipo'] ?? item['categoria'] ?? '-';

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.science_outlined,
                            color: Colors.teal,
                          ),
                          title: Text(
                            nomeInsumo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Categoria: $tipo"),
                          trailing: Text(
                            "$qtd un.",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.teal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pedido.podeCancelar)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _solicitarCancelamento(context, docIdLimpo),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("Cancelar Pedido"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fechar"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
