import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal.shade700,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              "Detalhes do Pedido",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 550,
        height: 650,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('pedidos_insumos')
              .doc(chamado.id)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text("Pedido não encontrado ou foi excluído."),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final itens = List<Map<String, dynamic>>.from(data['itens'] ?? []);
            List<Map<String, dynamic>> historico =
                List<Map<String, dynamic>>.from(data['historico'] ?? []);

            if (historico.isEmpty) {
              DateTime dataCriacao = DateTime.now();
              if (data['dataSolicitacao'] is Timestamp) {
                dataCriacao = (data['dataSolicitacao'] as Timestamp).toDate();
              }
              historico.add({
                'status': 'Pendente',
                'data': dataCriacao.toIso8601String(),
                'observacao': 'Pedido de insumos realizado por $usuarioLogado',
              });
            }

            final obsLab = data['observacaoLaboratorio'] as String?;
            final statusAtual = data['status'] ?? 'Pendente';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DESTINO",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chamado.laboratorioNome,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: obterCorStatus(statusAtual).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: obterCorStatus(statusAtual).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          statusAtual.toUpperCase(),
                          style: TextStyle(
                            color: obterCorStatus(statusAtual),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (obsLab != null && obsLab.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.amber.shade800,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Retorno do Laboratório:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  obsLab,
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    "MATERIAIS SOLICITADOS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itens.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final item = itens[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.vaccines_rounded,
                                  size: 16,
                                  color: Colors.teal.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['descricao'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['tipo'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${item['quantidade']} UN",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "LINHA DO TEMPO",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: historico.asMap().entries.map((entry) {
                        final index = entry.key;
                        final h = entry.value;
                        final isLast = index == historico.length - 1;

                        DateTime dataH;
                        if (h['data'] is String) {
                          dataH = DateTime.parse(h['data']);
                        } else if (h['data'] is Timestamp) {
                          dataH = (h['data'] as Timestamp).toDate();
                        } else {
                          dataH = DateTime.now();
                        }

                        final String dataFormatada =
                            "${dataH.day.toString().padLeft(2, '0')}/${dataH.month.toString().padLeft(2, '0')}/${dataH.year}";
                        final String horaFormatada =
                            "${dataH.hour.toString().padLeft(2, '0')}:${dataH.minute.toString().padLeft(2, '0')}";
                        final corHistorico = obterCorStatus(h['status'] ?? '');

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: corHistorico,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Colors.grey.shade300,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            h['status'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: corHistorico,
                                            ),
                                          ),
                                          Text(
                                            "$dataFormatada - $horaFormatada",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (h['observacao'] != null &&
                                          (h['observacao'] as String)
                                              .isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  h['observacao'],
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade800,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        // 💡 Botão Inteligente: Trava Blindada com contains()
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pedidos_insumos')
              .doc(chamado.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox.shrink();
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final statusLower = (data['status'] ?? chamado.status)
                .toString()
                .toLowerCase();

            // Usando contains para driblar acentos, maiúsculas e "o/a"
            final bool isFinalizado =
                statusLower.contains('entregue') ||
                statusLower.contains('finalizad') ||
                statusLower.contains('conclu') ||
                statusLower.contains('cancelad');

            if (isFinalizado) return const SizedBox.shrink();

            return TextButton(
              onPressed: () async {
                if (context.mounted) {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Cancelar Pedido?"),
                      content: const Text(
                        "Tem certeza que deseja cancelar a solicitação destes insumos?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text("Não, Voltar"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            "Sim, Cancelar",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('pedidos_insumos')
                        .doc(chamado.id)
                        .update({
                          'status': 'Cancelado',
                          'historico': FieldValue.arrayUnion([
                            {
                              'status': 'Cancelado',
                              'data': DateTime.now().toIso8601String(),
                              'observacao': 'Cancelado por: $usuarioLogado',
                            },
                          ]),
                        });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pedido cancelado com sucesso."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text(
                "Cancelar Pedido",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Fechar",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
