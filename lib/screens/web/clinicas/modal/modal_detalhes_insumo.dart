import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/models/clinica_model.dart';

class ModalDetalhesInsumo extends StatelessWidget {
  final ChamadoColetaModel chamado;
  final Clinica clinicaContexto;
  final String usuarioLogado;
  final Color Function(String) obterCorStatus;

  const ModalDetalhesInsumo({
    super.key,
    required this.chamado,
    required this.clinicaContexto,
    required this.usuarioLogado,
    required this.obterCorStatus,
  });

  // 🎨 Mapeamento Visual dos Status do Pedido de Insumos
  Color _obterCorStatusInsumo(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'aguardando_analise':
        return Colors.orange.shade700;
      case 'em_separacao':
      case 'em separação':
        return Colors.blue.shade700;
      case 'aguardando_coleta':
      case 'aguardando coleta':
        return Colors.purple.shade700;
      case 'entregue':
      case 'concluído':
      case 'concluido':
        return Colors.green.shade700;
      case 'recusado':
      case 'cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _obterTextoStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'aguardando_analise':
        return 'Pendente / Em Análise pelo Lab';
      case 'em_separacao':
      case 'em separação':
        return 'Em Separação no Laboratório';
      case 'aguardando_coleta':
      case 'aguardando coleta':
        return 'Pronto / Aguardando Motoboy';
      case 'entregue':
      case 'concluído':
      case 'concluido':
        return 'Pedido Entregue';
      case 'recusado':
      case 'cancelado':
        return 'Pedido Recusado pelo Laboratório';
      default:
        return status;
    }
  }

  IconData _obterIconeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'aguardando_analise':
        return Icons.hourglass_top_rounded;
      case 'em_separacao':
      case 'em separação':
        return Icons.inventory_2_outlined;
      case 'aguardando_coleta':
      case 'aguardando coleta':
        return Icons.sports_motorsports_outlined;
      case 'entregue':
      case 'concluído':
      case 'concluido':
        return Icons.check_circle_outline;
      case 'recusado':
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Helper para formatar Timestamp/DateTime em 'dd/MM/yyyy HH:mm'
  String _formatarDataHora(dynamic valorData) {
    if (valorData == null) return '';
    try {
      if (valorData is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(valorData.toDate());
      } else if (valorData is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(valorData);
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Remove o prefixo interno 'INSUMO_' para buscar o ID real no Firestore
    final docIdLimpo = chamado.id.replaceFirst('INSUMO_', '');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Insumos - ${chamado.laboratorioNome}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('pedidos_insumos')
              .doc(docIdLimpo)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Não foi possível localizar os dados deste pedido de insumos.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'Pendente').toString();

            // 1. DADOS DO SOLICITANTE DA CLÍNICA
            final String solicitanteNome =
                data['usuarioSolicitante'] ??
                data['solicitanteNome'] ??
                data['usuarioLogado'] ??
                'Não informado';

            final rawData = data['dataSolicitacao'] ?? data['dataPedido'];
            final dataFormatada = rawData != null
                ? _formatarDataHora(rawData)
                : _formatarDataHora(chamado.dataCriacao);

            // 2. DADOS DA OBSERVAÇÃO/RECUSA DO LABORATÓRIO
            final String justificativaLab =
                data['justificativaLab'] ?? data['observacaoLaboratorio'] ?? '';
            final String usuarioLabObs =
                data['usuarioObservacaoLab'] ??
                data['usuarioRespostaLab'] ??
                data['laboratorioUsuario'] ??
                '';
            final String dataLabObsFormatada = _formatarDataHora(
              data['dataObservacaoLab'] ?? data['dataRespostaLab'],
            );

            final List itens = data['itens'] ?? [];

            final isRecusado =
                status.toLowerCase() == 'recusado' ||
                status.toLowerCase() == 'cancelado';

            final corStatus = _obterCorStatusInsumo(status);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. HEADER DE STATUS DESTACADO (COM QUEM SOLICITOU + DATA/HORA)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: corStatus.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: corStatus.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _obterIconeStatus(status),
                          color: corStatus,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _obterTextoStatus(status),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: corStatus,
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
                                      text: "Solicitado em: $dataFormatada",
                                    ),
                                    const TextSpan(text: " por "),
                                    TextSpan(
                                      text: solicitanteNome,
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

                  // 2. 📌 ALERTA DE OBSERVAÇÃO OU RECUSA DO LABORATÓRIO (COM AUTOR E DATA/HORA)
                  if (justificativaLab.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRecusado
                            ? Colors.red.shade50
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isRecusado
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
                                isRecusado
                                    ? Icons.error_outline
                                    : Icons.info_outline,
                                color: isRecusado
                                    ? Colors.red.shade700
                                    : Colors.amber.shade900,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRecusado
                                    ? "Motivo da Recusa do Pedido:"
                                    : "Observação do Laboratório:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isRecusado
                                      ? Colors.red.shade700
                                      : Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            justificativaLab,
                            style: TextStyle(
                              color: isRecusado
                                  ? Colors.red.shade900
                                  : Colors.black87,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),

                          // Autoria e Data/Hora da Observação
                          if (usuarioLabObs.isNotEmpty ||
                              dataLabObsFormatada.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Por: ${usuarioLabObs.isNotEmpty ? usuarioLabObs : 'Laboratório'}" +
                                    (dataLabObsFormatada.isNotEmpty
                                        ? " em $dataLabObsFormatada"
                                        : ""),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: isRecusado
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

                  // 3. LISTA DE MATERIAIS SOLICITADOS
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
                        "${itens.length} tipo(s)",
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
                      itemCount: itens.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = itens[index];
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
            );
          },
        ),
      ),
      actions: [
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
    );
  }
}
