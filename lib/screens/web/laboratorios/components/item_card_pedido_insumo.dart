import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';
import 'modal_acao_pedido_insumo.dart';

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
    Map<String, dynamic> dataRaw,
  ) async {
    setState(() => _processandoEncaminhamento = true);

    final resultado = await controller.encaminharParaEntrega(
      pedidoId: widget.doc.id,
      pedidoData: dataRaw,
    );

    if (mounted) {
      setState(() => _processandoEncaminhamento = false);
      _exibirSnackBar(resultado);
    }
  }

  // 💡 MÁGICA DE LOGÍSTICA: Extrai a hora exata da última mudança de status relevante!
  String _obterHoraUltimaAtualizacao(
    PedidoInsumoModel pedido,
    Map<String, dynamic> dataRaw,
    PedidoInsumoController controller,
  ) {
    final statusAtual = pedido.status.toLowerCase();
    final historico = (dataRaw['historico'] as List<dynamic>?) ?? [];

    // Tenta achar no histórico o exato momento em que o status atual foi definido
    if (historico.isNotEmpty) {
      for (var i = historico.length - 1; i >= 0; i--) {
        final item = historico[i] as Map<String, dynamic>;
        final statusHist = (item['status'] ?? '').toString().toLowerCase();

        if (statusAtual.contains(statusHist) ||
            statusHist.contains(statusAtual)) {
          final dataHist = item['data'];
          if (dataHist != null) {
            // Retorna apenas a "Hora:Minuto" da formatação completa (ex: de "25/08/2026 21:15" para "21:15")
            return controller.formatarData(dataHist).split(' ').last;
          }
        }
      }
    }

    // Fallback: Se não achar no histórico, tenta a dataAtualizacao do doc inteiro
    if (pedido.dataAtualizacao != null) {
      return controller.formatarData(pedido.dataAtualizacao).split(' ').last;
    }

    // Último Fallback de segurança: Data de Criação do Pedido
    return controller.formatarData(pedido.dataSolicitacao).split(' ').last;
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<PedidoInsumoController?>() ?? PedidoInsumoController();

    final pedido = PedidoInsumoModel.fromFirestore(widget.doc);
    final dataRaw = widget.doc.data() as Map<String, dynamic>;

    final bool isEmSeparacao =
        pedido.status.toLowerCase() == 'em_separacao' ||
        pedido.status.toLowerCase() == 'em separação';

    final String codigoOriginal =
        dataRaw['codigoAcompanhamento'] ??
        dataRaw['codigo'] ??
        dataRaw['chamadoId'] ??
        pedido.id;
    final String codigoFormatado = codigoOriginal.length >= 6
        ? codigoOriginal.substring(0, 6).toUpperCase()
        : codigoOriginal.toUpperCase();

    // Extração inteligente do tempo
    final String horaAtualizacao = _obterHoraUltimaAtualizacao(
      pedido,
      dataRaw,
      controller,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo: Status e Tempo Atualizado da Mudança (Agilidade Logística)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pedido.corStatus.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pedido.textoStatus,
                  style: TextStyle(
                    color: pedido.corStatus,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                horaAtualizacao,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            "Pedido #$codigoFormatado",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),

          Text(
            pedido.clinicaNome,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                "${pedido.itens.length} item(ns) na lista",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ModalAcaoPedidoInsumo(
                        pedido: pedido,
                        dataRaw: dataRaw,
                        controller: controller,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: BorderSide(color: Colors.indigo.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Detalhes",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (isEmSeparacao) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processandoEncaminhamento
                        ? null
                        : () => _encaminharParaEntrega(controller, dataRaw),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _processandoEncaminhamento
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Despachar",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
