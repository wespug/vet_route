import 'package:flutter/material.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/item_logistica_model.dart';

class ModalDetalhesItemView extends StatelessWidget {
  final ItemLogisticaModel item;
  final Clinica clinicaContexto;
  final String usuarioLogado;
  final ChamadoColetaController controller;

  const ModalDetalhesItemView({
    super.key,
    required this.item,
    required this.clinicaContexto,
    required this.usuarioLogado,
    required this.controller,
  });

  bool get _podeCancelar {
    final statusLower = item.status.toLowerCase();
    return !statusLower.contains('coletado') &&
        !statusLower.contains('em_rota') &&
        !statusLower.contains('em rota') &&
        !statusLower.contains('entregue') &&
        !statusLower.contains('concluido') &&
        !statusLower.contains('cancelado');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.isInsumo
                              ? Icons.inventory_2_rounded
                              : Icons.local_shipping_rounded,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Detalhes do Item: #${item.codigo}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Destino: ${item.laboratorioNome}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Conteúdo com Rolagem
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status e Tipo
                      Row(
                        children: [
                          Expanded(
                            child: _buildCardInfo(
                              titulo: "Status Atual",
                              valor: item.textoStatus,
                              corValor: item.corStatus,
                              icone: Icons.info_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCardInfo(
                              titulo: "Tipo de Operação",
                              valor: item.nomeTipoFormatado,
                              corValor: Colors.black87,
                              icone: Icons.category_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Se for Insumo, exibe a listagem de itens solicitados
                      if (item.isInsumo && item.itensInsumo.isNotEmpty) ...[
                        const Text(
                          "Itens Solicitados",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.itensInsumo.map((insumo) {
                              final nomeInsumo =
                                  insumo['descricao'] ??
                                  insumo['nomeInsumo'] ??
                                  insumo['nome'] ??
                                  'Insumo';
                              final qtd =
                                  insumo['quantidade'] ??
                                  insumo['quantidadeSolicitada'] ??
                                  insumo['qtd'] ??
                                  1;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "- $nomeInsumo",
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Qtd: $qtd",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Rastreamento GPS
                      const Text(
                        "Rastreamento em Tempo Real",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            Positioned(
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.radar,
                                      size: 14,
                                      color: Colors.indigo,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Localização sincronizada via GPS",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Histórico de Logs Oficial do Model com Linha do Tempo
                      const Text(
                        "Histórico do Pedido",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHistoricoLista(),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),

              // Rodapé com Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _podeCancelar
                      ? TextButton.icon(
                          onPressed: () => _confirmarCancelamento(context),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Cancelar Pedido",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Text(
                          "Cancelamento indisponível (já em andamento/concluído)",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Fechar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardInfo({
    required String titulo,
    required String valor,
    required Color corValor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icone, color: Colors.indigo.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: corValor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💡 AGORA A VIEW É "BURRA" E APENAS DESENHA O QUE O MODELO MANDA
  Widget _buildHistoricoLista() {
    final logs = item.historicoCompletoEOrdenado;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final bool isUltimo = index == logs.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna da Timeline (Bolinha + Tracinho)
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isUltimo ? Colors.indigo : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: isUltimo
                        ? Border.all(color: Colors.indigo.shade100, width: 3)
                        : null,
                  ),
                ),
                if (!isUltimo)
                  Container(width: 2, height: 50, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 16),

            // Coluna dos Dados Textuais
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isUltimo ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Por: ${log.usuario} em ${item.formatarData(log.data)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (log.observacao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Obs: ${log.observacao}",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarCancelamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Cancelamento"),
        content: const Text(
          "Deseja realmente cancelar esta solicitação? Esta ação não poderá ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Voltar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();

              try {
                await controller.cancelarItem(item, usuarioLogado);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Solicitação cancelada com sucesso."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao cancelar: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Sim, Cancelar"),
          ),
        ],
      ),
    );
  }
}
