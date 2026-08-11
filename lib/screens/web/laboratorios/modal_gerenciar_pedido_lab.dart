import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ModalGerenciarPedidoLab extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Color Function(String) obterCorStatus;
  final String Function(String) obterLabelStatus;
  final IconData Function(String) obterIconeStatus;
  final String usuarioLogado; // 👈 Passado para salvar quem atendeu no lab

  const ModalGerenciarPedidoLab({
    super.key,
    required this.doc,
    required this.obterCorStatus,
    required this.obterLabelStatus,
    required this.obterIconeStatus,
    this.usuarioLogado = 'Operador do Laboratório',
  });

  @override
  State<ModalGerenciarPedidoLab> createState() =>
      _ModalGerenciarPedidoLabState();
}

class _ModalGerenciarPedidoLabState extends State<ModalGerenciarPedidoLab> {
  final _formKey = GlobalKey<FormState>();
  final _justificativaController = TextEditingController();

  String _opcaoDecisao = 'aprovar_total';
  bool _salvando = false;

  // Helper para formatar datas e horas com segurança
  String _formatarDataHora(dynamic valorData) {
    if (valorData == null) return 'Data não disponível';
    try {
      if (valorData is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(valorData.toDate());
      } else if (valorData is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(valorData);
      }
    } catch (_) {}
    return 'Data inválida';
  }

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final statusAtual = (data['status'] ?? 'Pendente').toString();
    final List itens = data['itens'] ?? [];
    final String justificativaAnterior = data['justificativaLab'] ?? '';

    // 💡 Dados Detalhados do Solicitante
    final String nomeClinica =
        data['clinicaNome'] ?? data['nomeClinica'] ?? 'Clínica';
    final String nomeUsuarioSolicitante =
        data['usuarioSolicitante'] ??
        data['solicitanteNome'] ??
        data['usuarioLogado'] ??
        'Usuário não informado';

    final String dataPedidoFormatada = _formatarDataHora(
      data['dataSolicitacao'] ?? data['dataCriacao'] ?? data['dataPedido'],
    );

    final statusLower = statusAtual.toLowerCase();
    final isPendente = ['pendente', 'aguardando_analise'].contains(statusLower);
    final isEmSeparacao = [
      'em_separacao',
      'em separação',
    ].contains(statusLower);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(
            widget.obterIconeStatus(statusAtual),
            color: widget.obterCorStatus(statusAtual),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Detalhes do Pedido - ${widget.obterLabelStatus(statusAtual)}",
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- CARD COMPLETO DE SOLICITANTE, USUÁRIO E HORA ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.indigo,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nome da Clínica
                          Text(
                            "Solicitante: $nomeClinica",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // 2. Nome do Usuário Responsável pelo Pedido
                          Text(
                            "Usuário responsável: $nomeUsuarioSolicitante",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // 3. Data e Hora
                          Text(
                            "Data e Hora do Pedido: $dataPedidoFormatada",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Itens Solicitados para Conferência:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    "${itens.length} item(ns)",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de Materiais
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: itens.map((item) {
                    final nomeInsumo =
                        item['descricao'] ??
                        item['nomeInsumo'] ??
                        'Insumo Desconhecido';
                    final qtd =
                        item['quantidade'] ?? item['quantidadeSolicitada'] ?? 0;
                    final tipo = item['tipo'] ?? '-';

                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.vaccines_outlined,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        nomeInsumo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        "Categoria: $tipo",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        "$qtd un.",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.indigo,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Justificativa / Observação gravada anteriormente
              if (justificativaAnterior.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📌 Observação / Justificativa:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        justificativaAnterior,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Decision Radio Buttons (Aprovar / Parcial / Recusar)
              if (isPendente) ...[
                const Text(
                  "Decisão de Atendimento:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text(
                            "Aprovar Totalmente",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Todos os itens disponíveis em estoque.",
                          ),
                          value: 'aprovar_total',
                          groupValue: _opcaoDecisao,
                          activeColor: Colors.green,
                          onChanged: (val) =>
                              setState(() => _opcaoDecisao = val!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text(
                            "Aprovar Parcialmente",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Falta de estoque parcial ou ajuste necessário.",
                          ),
                          value: 'aprovar_parcial',
                          groupValue: _opcaoDecisao,
                          activeColor: Colors.orange.shade700,
                          onChanged: (val) =>
                              setState(() => _opcaoDecisao = val!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text(
                            "Recusar / Declinar Pedido",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Não será possível atender a este pedido.",
                          ),
                          value: 'recusar',
                          groupValue: _opcaoDecisao,
                          activeColor: Colors.red,
                          onChanged: (val) =>
                              setState(() => _opcaoDecisao = val!),
                        ),

                        if (_opcaoDecisao != 'aprovar_total') ...[
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextFormField(
                              controller: _justificativaController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: _opcaoDecisao == 'recusar'
                                    ? "Motivo da Recusa (Obrigatório)"
                                    : "Justificativa do Envio Parcial (Obrigatório)",
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? "Campo obrigatório"
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Instrução de Separação
              if (isEmSeparacao) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Confira os itens acima. Ao concluir a embalagem, clique no botão abaixo para disponibilizar o pacote para a rota do motoboy.",
                          style: TextStyle(color: Colors.blue, fontSize: 13),
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
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text("Fechar", style: TextStyle(color: Colors.grey)),
        ),

        // Botão de ação do status Pendente
        if (isPendente)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _opcaoDecisao == 'recusar'
                  ? Colors.red
                  : (_opcaoDecisao == 'aprovar_parcial'
                        ? Colors.orange.shade700
                        : Colors.indigo),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _salvando
                ? null
                : () async {
                    if (_opcaoDecisao != 'aprovar_total' &&
                        !_formKey.currentState!.validate()) {
                      return;
                    }
                    setState(() => _salvando = true);

                    try {
                      String novoStatus = _opcaoDecisao == 'recusar'
                          ? 'recusado'
                          : 'em_separacao';

                      await FirebaseFirestore.instance
                          .collection('pedidos_insumos')
                          .doc(widget.doc.id)
                          .update({
                            'status': novoStatus,
                            'justificativaLab': _justificativaController.text
                                .trim(),
                            'usuarioObservacaoLab':
                                widget.usuarioLogado, // 👈 Grava quem atendeu
                            'dataObservacaoLab':
                                FieldValue.serverTimestamp(), // 👈 Grava data/hora da resposta
                            'dataAtualizacao': FieldValue.serverTimestamp(),
                          });

                      if (mounted) Navigator.pop(context);
                    } finally {
                      setState(() => _salvando = false);
                    }
                  },
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _opcaoDecisao == 'recusar'
                        ? Icons.cancel_outlined
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(
              _opcaoDecisao == 'recusar'
                  ? "Confirmar Recusa"
                  : (_opcaoDecisao == 'aprovar_parcial'
                        ? "Aprovar Parcial e Iniciar Separação"
                        : "Aprovar e Iniciar Separação"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        // Botão de ação do status Em Separação
        if (isEmSeparacao)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _salvando
                ? null
                : () async {
                    setState(() => _salvando = true);
                    try {
                      await FirebaseFirestore.instance
                          .collection('pedidos_insumos')
                          .doc(widget.doc.id)
                          .update({
                            'status': 'aguardando_coleta',
                            'dataAtualizacao': FieldValue.serverTimestamp(),
                          });
                      if (mounted) Navigator.pop(context);
                    } finally {
                      setState(() => _salvando = false);
                    }
                  },
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sports_motorsports_outlined, size: 18),
            label: const Text(
              "Concluir Separação e Liberar para o Entregador",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
