import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
        !statusLower.contains('cancelado') &&
        !statusLower.contains('recusado');
  }

  DateTime _parseData(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is DateTime) return val;
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                  item.isInsumo ? 'pedidos_insumos' : 'chamados_coleta',
                )
                .doc(item.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.indigo),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text("Erro ao carregar dados em tempo real."),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              // 💡 CORREÇÃO: clinicaContexto pertence à View, não ao 'item'
              final String clinicaNome =
                  data['clinicaNome'] ?? clinicaContexto.nome;
              final String laboratorioNome =
                  data['laboratorioNome'] ?? item.laboratorioNome;
              final String? nomeEntregador = data['nomeEntregador']?.toString();
              final String observacao = data['observacao']?.toString() ?? '';

              final DateTime? dataAgendamento = data['dataAgendamento'] != null
                  ? _parseData(data['dataAgendamento'])
                  : null;
              final String dataAgendamentoStr = dataAgendamento != null
                  ? DateFormat('dd/MM/yyyy').format(dataAgendamento)
                  : 'A definir';

              // Histórico em Tempo Real
              final List<dynamic> rawLogs =
                  data['historicoLogs'] ?? data['historico'] ?? [];
              final List<HistoricoStatusLog> logsRealTime = rawLogs
                  .map(
                    (e) => HistoricoStatusLog.fromMap(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList();
              logsRealTime.sort((a, b) => a.data.compareTo(b.data));

              return Column(
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
                                  : Icons.science_rounded,
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
                                item.isInsumo
                                    ? "Pedido de Insumos"
                                    : "Coleta de Exames",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
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

                  // Conteúdo Rolável
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status
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

                          // Rota: Origem e Destino
                          const Text(
                            "Trajeto Logístico",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.storefront_rounded,
                                      color: Colors.indigo.shade400,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Origem da Coleta",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            clinicaNome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10.0,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 2,
                                      height: 20,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      color: Colors.indigo.shade400,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Destino da Entrega",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            laboratorioNome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Alocação do Entregador
                          if (nomeEntregador != null &&
                              nomeEntregador.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.two_wheeler_rounded,
                                      color: Colors.green.shade800,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Entregador Designado: $nomeEntregador",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Agendado para: $dataAgendamentoStr",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.amber.shade800,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Aguardando Entregador",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "O sistema fará a alocação de rota assim que disponível.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Material a ser Coletado (Para Exames)
                          if (!item.isInsumo && observacao.isNotEmpty) ...[
                            const Text(
                              "Material a ser Coletado",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                observacao,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Itens Insumo (Se Insumo)
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
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
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

                          // Histórico
                          const Text(
                            "Histórico do Pedido",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHistoricoLista(logsRealTime),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  // Rodapé
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
                              "Cancelamento indisponível",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
              );
            },
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

  Widget _buildHistoricoLista(List<HistoricoStatusLog> logs) {
    if (logs.isEmpty)
      return const Text(
        "Nenhum histórico disponível.",
        style: TextStyle(color: Colors.grey),
      );

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.status.toUpperCase(),
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
                          color: log.status.toLowerCase().contains('recusad')
                              ? Colors.red.shade700
                              : Colors.grey.shade600,
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
                      content: Text("Solicitação cancelada."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro: $e"),
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
