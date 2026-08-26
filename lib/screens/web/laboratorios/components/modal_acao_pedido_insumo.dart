import 'package:flutter/material.dart';
import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';

class ModalAcaoPedidoInsumo extends StatefulWidget {
  final PedidoInsumoModel pedido;
  final Map<String, dynamic> dataRaw;
  final PedidoInsumoController controller;

  const ModalAcaoPedidoInsumo({
    super.key,
    required this.pedido,
    required this.dataRaw,
    required this.controller,
  });

  @override
  State<ModalAcaoPedidoInsumo> createState() => _ModalAcaoPedidoInsumoState();
}

class _ModalAcaoPedidoInsumoState extends State<ModalAcaoPedidoInsumo> {
  DecisaoAtendimento? decisaoSelecionada;
  final controllerMotivo = TextEditingController();
  bool _processandoModal = false;

  late List<Map<String, dynamic>> _itensEditaveis;
  late List<TextEditingController> _qtdControllers;

  @override
  void initState() {
    super.initState();
    _itensEditaveis = List<Map<String, dynamic>>.from(
      widget.pedido.itens.map((item) => Map<String, dynamic>.from(item)),
    );

    _qtdControllers = _itensEditaveis.map((item) {
      final qtd =
          item['quantidade'] ??
          item['quantidadeSolicitada'] ??
          item['qtd'] ??
          0;
      return TextEditingController(text: qtd.toString());
    }).toList();
  }

  @override
  void dispose() {
    for (var ctrl in _qtdControllers) {
      ctrl.dispose();
    }
    controllerMotivo.dispose();
    super.dispose();
  }

  void _exibirSnackBar(ResultadoOperacao resultado) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado.mensagem),
        backgroundColor: resultado.sucesso ? Colors.indigo : Colors.orange,
      ),
    );
  }

  Future<void> _encaminharEntregaModal() async {
    setState(() => _processandoModal = true);
    final resultado = await widget.controller.encaminharParaEntrega(
      pedidoId: widget.pedido.id,
      pedidoData: widget.dataRaw,
    );
    if (mounted) {
      setState(() => _processandoModal = false);
      Navigator.pop(context);
      _exibirSnackBar(resultado);
    }
  }

  Future<void> _confirmarDecisao() async {
    if (decisaoSelecionada == DecisaoAtendimento.recusar &&
        controllerMotivo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, preencha o motivo da recusa."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _processandoModal = true);

    String obsFinal = controllerMotivo.text.trim();

    if (decisaoSelecionada == DecisaoAtendimento.aprovarParcial) {
      List<String> alteracoes = [];
      for (int i = 0; i < _itensEditaveis.length; i++) {
        final original = widget.pedido.itens[i];
        final novo = _itensEditaveis[i];

        final int qtdOriginal =
            original['quantidade'] ??
            original['quantidadeSolicitada'] ??
            original['qtd'] ??
            0;
        final int qtdNova =
            novo['quantidade'] ??
            novo['quantidadeSolicitada'] ??
            novo['qtd'] ??
            0;

        if (qtdOriginal != qtdNova) {
          final nome =
              original['descricao'] ??
              original['nomeInsumo'] ??
              original['nome'] ??
              'Item';
          alteracoes.add("$nome (de $qtdOriginal p/ $qtdNova un)");
        }
      }

      if (alteracoes.isNotEmpty) {
        final stringAlteracoes = "Ajustes: ${alteracoes.join(', ')}.";
        obsFinal = obsFinal.isEmpty
            ? stringAlteracoes
            : "$obsFinal [$stringAlteracoes]";
      }
    }

    final resultado = await widget.controller.processarDecisaoModal(
      pedidoId: widget.pedido.id,
      decisao: decisaoSelecionada!,
      motivoOuObservacao: obsFinal,
      itensAtualizados: _itensEditaveis,
    );

    if (mounted) {
      setState(() => _processandoModal = false);
      Navigator.pop(context);
      _exibirSnackBar(resultado);
    }
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

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final data = widget.dataRaw;

    final statusFormatado = pedido.textoStatus;
    final historico = (data['historico'] as List<dynamic>?) ?? [];
    final nomeEntregador = data['nomeEntregador']?.toString();

    // 💡 PADRONIZAÇÃO DO CÓDIGO (Igual à Tabela Unificada: 6 letras maiúsculas)
    final String codigoFormatado = pedido.codigo.length >= 6
        ? pedido.codigo.substring(0, 6).toUpperCase()
        : pedido.codigo.toUpperCase();

    String ultimaObservacao = '';
    String dataAcao = '';
    String usuarioAcao = 'Operador do Laboratório';

    if (historico.isNotEmpty) {
      final ultimoHist = historico.last as Map<String, dynamic>;
      ultimaObservacao = ultimoHist['observacao'] ?? '';
      dataAcao = widget.controller.formatarData(ultimoHist['data']);
      if (ultimoHist['usuario'] != null &&
          ultimoHist['usuario'].toString().isNotEmpty) {
        usuarioAcao = ultimoHist['usuario'].toString();
      }
    }

    if (pedido.isRecusadoOuCancelado) {
      if (data['usuarioCancelamento'] != null &&
          data['usuarioCancelamento'].toString().isNotEmpty) {
        usuarioAcao = data['usuarioCancelamento'].toString();
      }
      if (data['dataCancelamento'] != null) {
        dataAcao = widget.controller.formatarData(data['dataCancelamento']);
      }
      if (pedido.justificativaLab.isNotEmpty) {
        ultimaObservacao = pedido.justificativaLab;
      }
    }

    final bool isPendente = pedido.podeCancelar;
    final bool isEmSeparacao =
        pedido.status.toLowerCase() == 'em_separacao' ||
        pedido.status.toLowerCase() == 'em separação';

    return AlertDialog(
      backgroundColor: const Color(0xFFF4F4F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    pedido.isRecusadoOuCancelado
                        ? Icons.cancel_outlined
                        : Icons.assignment_outlined,
                    color: pedido.corStatus,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pedido #$codigoFormatado - $statusFormatado", // 💡 ID Formatado no Título
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
                            "Solicitante: ${pedido.clinicaNome}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Código de Rastreio: #$codigoFormatado", // 💡 ID Formatado em Destaque
                            style: TextStyle(
                              color: Colors.indigo.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Solicitado em: ${pedido.formatarData(pedido.dataSolicitacao)}",
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
              if (nomeEntregador != null && nomeEntregador.isNotEmpty) ...[
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    "${pedido.itens.length} item(ns)",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                  children: List.generate(_itensEditaveis.length, (index) {
                    final item = _itensEditaveis[index];
                    final isParcial =
                        isPendente &&
                        decisaoSelecionada == DecisaoAtendimento.aprovarParcial;

                    final int qtdOriginal =
                        widget.pedido.itens[index]['quantidade'] ??
                        widget.pedido.itens[index]['quantidadeSolicitada'] ??
                        widget.pedido.itens[index]['qtd'] ??
                        0;
                    final int qtdAtual =
                        item['quantidade'] ??
                        item['quantidadeSolicitada'] ??
                        item['qtd'] ??
                        0;

                    final String qtdKey =
                        item.containsKey('quantidadeSolicitada')
                        ? 'quantidadeSolicitada'
                        : item.containsKey('qtd')
                        ? 'qtd'
                        : 'quantidade';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.vaccines_outlined,
                            color: qtdAtual == 0 && isParcial
                                ? Colors.grey.shade400
                                : Colors.indigo,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['descricao'] ??
                                      item['nomeInsumo'] ??
                                      item['nome'] ??
                                      'Insumo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    decoration: qtdAtual == 0 && isParcial
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: qtdAtual == 0 && isParcial
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Categoria: ${item['tipo'] ?? item['categoria'] ?? '-'}",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                if (isParcial && qtdAtual != qtdOriginal)
                                  Text(
                                    "Qtd Original: $qtdOriginal un.",
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          if (isParcial)
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () {
                                    int val =
                                        int.tryParse(
                                          _qtdControllers[index].text,
                                        ) ??
                                        0;
                                    if (val > 0) {
                                      val--;
                                      _qtdControllers[index].text = val
                                          .toString();
                                      item[qtdKey] = val;
                                      setState(() {});
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 45,
                                  height: 35,
                                  child: TextField(
                                    controller: _qtdControllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (val) {
                                      int parsed = int.tryParse(val) ?? 0;
                                      if (parsed < 0) parsed = 0;
                                      item[qtdKey] = parsed;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green.shade600,
                                  ),
                                  onPressed: () {
                                    int val =
                                        int.tryParse(
                                          _qtdControllers[index].text,
                                        ) ??
                                        0;
                                    val++;
                                    _qtdControllers[index].text = val
                                        .toString();
                                    item[qtdKey] = val;
                                    setState(() {});
                                  },
                                ),
                              ],
                            )
                          else
                            Text(
                              "$qtdAtual un.",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              if (isPendente) ...[
                const Text(
                  "Decisão de Atendimento:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) {
                          for (int i = 0; i < _itensEditaveis.length; i++) {
                            final orig =
                                widget.pedido.itens[i]['quantidade'] ??
                                widget
                                    .pedido
                                    .itens[i]['quantidadeSolicitada'] ??
                                widget.pedido.itens[i]['qtd'] ??
                                0;
                            final key =
                                _itensEditaveis[i].containsKey(
                                  'quantidadeSolicitada',
                                )
                                ? 'quantidadeSolicitada'
                                : _itensEditaveis[i].containsKey('qtd')
                                ? 'qtd'
                                : 'quantidade';
                            _itensEditaveis[i][key] = orig;
                            _qtdControllers[i].text = orig.toString();
                          }
                          setState(() => decisaoSelecionada = val);
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
                          "Ajuste a quantidade entregue de cada item na lista acima.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) =>
                            setState(() => decisaoSelecionada = val),
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
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) =>
                            setState(() => decisaoSelecionada = val),
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
                          decisaoSelecionada == DecisaoAtendimento.recusar
                          ? "Motivo da Recusa (Obrigatório)"
                          : "Observações do Atendimento",
                      labelStyle: TextStyle(
                        color: decisaoSelecionada == DecisaoAtendimento.recusar
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
                              decisaoSelecionada == DecisaoAtendimento.recusar
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
                          color: pedido.isRecusadoOuCancelado
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
                        _construirTextoObservacaoFormatado(ultimaObservacao),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 24, bottom: 20, top: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _processandoModal
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.local_shipping_rounded, size: 18),
            label: const Text("Encaminhar para Entrega"),
            onPressed: _processandoModal ? null : _encaminharEntregaModal,
          ),
        if (isPendente && decisaoSelecionada != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: decisaoSelecionada == DecisaoAtendimento.recusar
                  ? const Color(0xFFE53935)
                  : Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _processandoModal
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    decisaoSelecionada == DecisaoAtendimento.recusar
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
            label: Text(
              decisaoSelecionada == DecisaoAtendimento.recusar
                  ? "Confirmar Recusa"
                  : decisaoSelecionada == DecisaoAtendimento.aprovarParcial
                  ? "Salvar Aprovação Parcial"
                  : "Aprovar Totalmente",
            ),
            onPressed: _processandoModal ? null : _confirmarDecisao,
          ),
      ],
    );
  }
}
