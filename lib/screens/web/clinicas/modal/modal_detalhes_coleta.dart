import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class ModalDetalhesColeta extends StatelessWidget {
  final ChamadoColetaModel chamado;
  final Clinica clinicaContexto;
  final String usuarioLogado;
  final Color Function(String) obterCorStatus;

  const ModalDetalhesColeta({
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
          color: Colors.indigo.shade700,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(
              chamado.isEmergencia
                  ? Icons.flash_on_rounded
                  : Icons.local_shipping_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            const Text(
              "Detalhes da Coleta",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            if (chamado.isEmergencia)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "URGÊNCIA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      content: SizedBox(
        width: 600,
        height: 700,
        // 💡 MÁGICA: Usamos StreamBuilder para o modal atualizar sozinho em Tempo Real!
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chamados_coleta')
              .doc(chamado.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Coleta não encontrada."));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final statusAtual = data['status'] ?? chamado.status;
            final obsLab = data['observacaoLaboratorio'] as String?;
            final obsClinica = data['observacao'] as String?;

            // Dados do Entregador
            final entregadorNome = data['entregadorNome'] as String?;
            final entregadorTipo =
                data['entregadorTipo']
                    as String?; // "Plataforma Vet Route" ou "Terceirizado"

            // Tratamento do Histórico com Marco Zero
            List<Map<String, dynamic>> historico =
                List<Map<String, dynamic>>.from(data['historico'] ?? []);
            if (historico.isEmpty) {
              DateTime dataCriacao = chamado.dataCriacao;
              historico.add({
                'status': 'Aguardando Entregador',
                'data': dataCriacao.toIso8601String(),
                'observacao': 'Coleta solicitada por $usuarioLogado',
              });
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CABEÇALHO (DESTINO E STATUS) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LABORATÓRIO DESTINO",
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

                  // --- OBSERVAÇÃO DA CLÍNICA ---
                  if (obsClinica != null && obsClinica.isNotEmpty) ...[
                    Text(
                      "MATERIAL A SER COLETADO",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
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
                      child: Text(
                        obsClinica,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- OBSERVAÇÃO DO LABORATÓRIO ---
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
                                  "Aviso do Laboratório:",
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

                  // --- CARTÃO DO ENTREGADOR ---
                  Text(
                    "DADOS DO ENTREGADOR",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: entregadorNome != null
                            ? Colors.indigo.shade200
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: entregadorNome != null
                              ? Colors.indigo.shade50
                              : Colors.grey.shade100,
                          child: Icon(
                            Icons.person_pin,
                            size: 28,
                            color: entregadorNome != null
                                ? Colors.indigo
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entregadorNome ?? "Aguardando atribuição...",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: entregadorNome != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                ),
                              ),
                              if (entregadorTipo != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entregadorTipo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- MAPA (PLACEHOLDER PARA TEMPO REAL) ---
                  Text(
                    "RASTREAMENTO",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Mapa em Tempo Real",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "A localização do motoboy aparecerá aqui.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- TIMELINE DE HISTÓRICO ---
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
              .collection('chamados_coleta')
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
                bool confirm = await showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text("Cancelar Coleta?"),
                    content: const Text(
                      "Tem certeza que deseja cancelar esta solicitação de coleta?",
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
                      .collection('chamados_coleta')
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
                        content: Text("Coleta cancelada com sucesso."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text(
                "Cancelar Coleta",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
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
