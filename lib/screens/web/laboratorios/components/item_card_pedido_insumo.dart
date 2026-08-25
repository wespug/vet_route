import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:vet_route/controllers/pedido_insumo_controller.dart';

class ItemCardPedidoInsumo extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const ItemCardPedidoInsumo({super.key, required this.doc});

  @override
  State<ItemCardPedidoInsumo> createState() => _ItemCardPedidoInsumoState();
}

class _ItemCardPedidoInsumoState extends State<ItemCardPedidoInsumo> {
  bool _processandoEncaminhamento = false;

  void _exibirSnackBar(ResultadoOperacao resultado) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado.mensagem),
        backgroundColor: resultado.sucesso ? Colors.indigo : Colors.orange,
      ),
    );
  }

  Future<void> _encaminharParaEntrega(
    PedidoInsumoController controller,
    Map<String, dynamic> data,
  ) async {
    setState(() => _processandoEncaminhamento = true);

    final resultado = await controller.encaminharParaEntrega(
      pedidoId: widget.doc.id,
      pedidoData: data,
    );

    if (mounted) {
      setState(() => _processandoEncaminhamento = false);
      _exibirSnackBar(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tenta obter via Provider; se não houver Provider acoplado, cria uma instância local
    final controller =
        context.watch<PedidoInsumoController?>() ?? PedidoInsumoController();

    final data = widget.doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'Pendente').toString();
    final estilo = controller.obterEstiloStatus(status);
    final clinicaNome = data['clinicaNome'] ?? 'Clínica Não Informada';
    final dataPedido = controller.formatarData(data['dataSolicitacao']);
    final itens = (data['itens'] as List<dynamic>?) ?? [];
    final bool isEmSeparacao =
        status.toLowerCase() == 'em_separacao' ||
        status.toLowerCase() == 'em separação';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: estilo['bgIcon'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(estilo['icon'], color: estilo['cor'], size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicaNome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    if (dataPedido.isNotEmpty)
                      Text(
                        "Solicitado em: $dataPedido",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: estilo['bgBadge'],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: estilo['borderBadge']),
                ),
                child: Text(
                  estilo['label'],
                  style: TextStyle(
                    color: estilo['cor'],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${itens.length} item(ns) solicitado(s)",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  if (isEmSeparacao) ...[
                    ElevatedButton.icon(
                      onPressed: _processandoEncaminhamento
                          ? null
                          : () => _encaminharParaEntrega(controller, data),
                      icon: _processandoEncaminhamento
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.local_shipping_rounded, size: 16),
                      label: const Text(
                        "Encaminhar p/ Entrega",
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () =>
                        _exibirModalDetalhes(context, controller, data),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text("Ver Detalhes"),
                    style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirTextoObservacaoFormatado(String observacao) {
    if (observacao.isEmpty) return const SizedBox.shrink();

    String prefixoBold = '';
    String textoNormal = observacao;

    if (observacao.startsWith('Aprovado parcialmente:')) {
      prefixoBold = 'Aprovado parcialmente: ';
      textoNormal = observacao
          .substring('Aprovado parcialmente:'.length)
          .trim();
    } else if (observacao.startsWith('Aprovado totalmente:')) {
      prefixoBold = 'Aprovado totalmente: ';
      textoNormal = observacao.substring('Aprovado totalmente:'.length).trim();
    } else if (observacao.startsWith('Aprovado parcialmente.')) {
      prefixoBold = 'Aprovado parcialmente. ';
      textoNormal = observacao
          .substring('Aprovado parcialmente.'.length)
          .trim();
    }

    if (prefixoBold.isNotEmpty) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            const TextSpan(
              text: "Observação: ",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            TextSpan(
              text: prefixoBold,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            TextSpan(
              text: textoNormal,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      );
    }

    return Text(
      "Observação: $observacao",
      style: const TextStyle(color: Colors.black87, fontSize: 13),
    );
  }

  void _exibirModalDetalhes(
    BuildContext context,
    PedidoInsumoController controller,
    Map<String, dynamic> data,
  ) {
    final statusRaw = (data['status'] ?? 'Pendente / Análise').toString();
    final statusFormatado = controller.formatarStatusAmigavel(statusRaw);
    final itens = (data['itens'] as List<dynamic>?) ?? [];
    final historico = (data['historico'] as List<dynamic>?) ?? [];
    final dataPedido = controller.formatarData(data['dataSolicitacao']);
    final nomeEntregador = data['nomeEntregador']?.toString();

    final bool isCancelado =
        statusRaw.toLowerCase() == 'cancelado' ||
        statusRaw.toLowerCase().contains('recusado');

    String ultimaObservacao = '';
    String dataAcao = '';
    String usuarioAcao = 'Operador do Laboratório';

    if (historico.isNotEmpty) {
      final ultimoHist = historico.last as Map<String, dynamic>;
      ultimaObservacao = ultimoHist['observacao'] ?? '';
      dataAcao = controller.formatarData(ultimoHist['data']);
      if (ultimoHist['usuario'] != null &&
          ultimoHist['usuario'].toString().isNotEmpty) {
        usuarioAcao = ultimoHist['usuario'].toString();
      }
    }

    // Se o pedido foi cancelado, busca as credenciais de quem cancelou e a hora
    if (isCancelado) {
      if (data['usuarioCancelamento'] != null &&
          data['usuarioCancelamento'].toString().isNotEmpty) {
        usuarioAcao = data['usuarioCancelamento'].toString();
      }
      if (data['dataCancelamento'] != null) {
        dataAcao = controller.formatarData(data['dataCancelamento']);
      }
      if (data['justificativaLab'] != null &&
          data['justificativaLab'].toString().isNotEmpty) {
        ultimaObservacao = data['justificativaLab'].toString();
      }
    }

    final bool isPendente =
        statusRaw.toLowerCase().contains('pendente') ||
        statusRaw.toLowerCase().contains('análise') ||
        statusRaw.toLowerCase().contains('analise');

    final bool isEmSeparacao =
        statusRaw.toLowerCase() == 'em_separacao' ||
        statusRaw.toLowerCase() == 'em separação';

    DecisaoAtendimento? decisaoSelecionada;
    final controllerMotivo = TextEditingController();

    showDialog(
      context: context,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF4F4F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCancelado
                                ? Icons.cancel_outlined
                                : Icons.assignment_outlined,
                            color: isCancelado
                                ? Colors.redAccent
                                : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Detalhes do Pedido - $statusFormatado",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_box_rounded,
                                color: Colors.indigo,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Solicitante: ${data['clinicaNome'] ?? 'Clínica'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (dataPedido.isNotEmpty)
                                    Text(
                                      "Solicitado em: $dataPedido",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (nomeEntregador != null &&
                          nomeEntregador.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sports_motorsports_rounded,
                                color: Colors.orange.shade900,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Entregador Designado: $nomeEntregador",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Itens Solicitados para Conferência:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "${itens.length} item(ns)",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: itens.map((item) {
                            final map = item as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.vaccines_outlined,
                                    color: Colors.indigo,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          map['descricao'] ?? 'Insumo',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          "Categoria: ${map['tipo'] ?? 'Insumo'}",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${map['quantidade'] ?? 0} un.",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isPendente) ...[
                        const Text(
                          "Decisão de Atendimento:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<DecisaoAtendimento>(
                                activeColor: Colors.indigo,
                                value: DecisaoAtendimento.aprovarTotal,
                                groupValue: decisaoSelecionada,
                                title: const Text(
                                  "Aprovar Totalmente",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Todos os itens disponíveis em estoque.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onChanged: (val) {
                                  setModalState(() => decisaoSelecionada = val);
                                },
                              ),
                              const Divider(height: 1),
                              RadioListTile<DecisaoAtendimento>(
                                activeColor: Colors.indigo,
                                value: DecisaoAtendimento.aprovarParcial,
                                groupValue: decisaoSelecionada,
                                title: const Text(
                                  "Aprovar Parcialmente",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Falta de estoque parcial ou ajuste necessário.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onChanged: (val) {
                                  setModalState(() => decisaoSelecionada = val);
                                },
                              ),
                              const Divider(height: 1),
                              RadioListTile<DecisaoAtendimento>(
                                activeColor: Colors.redAccent,
                                value: DecisaoAtendimento.recusar,
                                groupValue: decisaoSelecionada,
                                title: const Text(
                                  "Recusar / Declinar Pedido",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Não será possível atender a este pedido.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onChanged: (val) {
                                  setModalState(() => decisaoSelecionada = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        if (decisaoSelecionada != null) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: controllerMotivo,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText:
                                  decisaoSelecionada ==
                                      DecisaoAtendimento.recusar
                                  ? "Motivo da Recusa (Obrigatório)"
                                  : "Observações do Atendimento",
                              labelStyle: TextStyle(
                                color:
                                    decisaoSelecionada ==
                                        DecisaoAtendimento.recusar
                                    ? Colors.redAccent
                                    : Colors.indigo,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      decisaoSelecionada ==
                                          DecisaoAtendimento.recusar
                                      ? Colors.redAccent
                                      : Colors.indigo,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Processado por: $usuarioAcao",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isCancelado
                                      ? Colors.red.shade700
                                      : Colors.indigo,
                                ),
                              ),
                              if (dataAcao.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "Data da Ação: $dataAcao",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (ultimaObservacao.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _construirTextoObservacaoFormatado(
                                  ultimaObservacao,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                right: 24,
                bottom: 20,
                top: 10,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(modalContext),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
                if (isEmSeparacao)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: const Text("Encaminhar para Entrega"),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      _encaminharParaEntrega(controller, data);
                    },
                  ),
                if (isPendente && decisaoSelecionada != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          decisaoSelecionada == DecisaoAtendimento.recusar
                          ? const Color(0xFFE53935)
                          : Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      decisaoSelecionada == DecisaoAtendimento.recusar
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      decisaoSelecionada == DecisaoAtendimento.recusar
                          ? "Confirmar Recusa"
                          : decisaoSelecionada ==
                                DecisaoAtendimento.aprovarParcial
                          ? "Aprovar Parcialmente"
                          : "Aprovar Totalmente",
                    ),
                    onPressed: () async {
                      final resultado = await controller.processarDecisaoModal(
                        pedidoId: widget.doc.id,
                        decisao: decisaoSelecionada!,
                        motivoOuObservacao: controllerMotivo.text,
                      );

                      if (modalContext.mounted) {
                        Navigator.pop(modalContext);
                        _exibirSnackBar(resultado);
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
