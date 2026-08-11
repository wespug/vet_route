import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';
import 'package:vet_route/models/rota_model.dart';
import 'package:vet_route/repositories/pedido_insumo_repository.dart';
import 'package:vet_route/repositories/rota_repository.dart';

enum DecisaoAtendimento { aprovarTotal, aprovarParcial, recusar }

class ResultadoOperacao {
  final bool sucesso;
  final String mensagem;

  ResultadoOperacao({required this.sucesso, required this.mensagem});
}

class PedidoInsumoController extends ChangeNotifier {
  final PedidoInsumoRepository _repository = PedidoInsumoRepository();
  final RotaRepository _rotaRepository = RotaRepository();

  List<PedidoInsumoModel> pedidos = [];
  bool carregando = true;

  // --- ESCUTA DE PEDIDOS EM TEMPO REAL ---

  void escutarPedidos(String laboratorioId) {
    _repository
        .streamPedidosPorLaboratorio(laboratorioId)
        .listen(
          (lista) {
            pedidos = lista;
            carregando = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Erro ao escutar pedidos: $e");
            carregando = false;
            notifyListeners();
          },
        );
  }

  Future<void> alterarStatus(String pedidoId, String novoStatus) async {
    try {
      await _repository.atualizarStatusPedido(pedidoId, novoStatus);
    } catch (e) {
      debugPrint("Erro ao atualizar status: $e");
      rethrow;
    }
  }

  // --- REGRAS DE NEGÓCIO E HISTÓRICO ---

  /// Atualiza o status registrando o histórico detalhado através do PedidoInsumoRepository
  Future<ResultadoOperacao> atualizarStatusDetalhado({
    required String pedidoId,
    required String novoStatus,
    required String observacao,
    String? entregadorId,
    String? nomeEntregador,
  }) async {
    try {
      final dataAtual = DateTime.now().toIso8601String();

      final Map<String, dynamic> itemHistorico = {
        'status': novoStatus,
        'data': dataAtual,
        'observacao': observacao,
        'usuario': 'Operador do Laboratório',
      };

      if (entregadorId != null) itemHistorico['entregadorId'] = entregadorId;
      if (nomeEntregador != null) {
        itemHistorico['nomeEntregador'] = nomeEntregador;
      }

      await _repository.atualizarStatusDetalhado(
        pedidoId: pedidoId,
        novoStatus: novoStatus,
        itemHistorico: itemHistorico,
        entregadorId: entregadorId,
        nomeEntregador: nomeEntregador,
      );

      return ResultadoOperacao(
        sucesso: true,
        mensagem: "Pedido atualizado com sucesso!",
      );
    } catch (e) {
      return ResultadoOperacao(
        sucesso: false,
        mensagem: "Erro ao atualizar pedido: $e",
      );
    }
  }

  /// Processa a decisão vinda do Modal do Card (Aprovar Total, Parcial ou Recusar)
  Future<ResultadoOperacao> processarDecisaoModal({
    required String pedidoId,
    required DecisaoAtendimento decisao,
    required String motivoOuObservacao,
  }) async {
    String novoStatus = 'em_separacao';
    String obs = motivoOuObservacao.trim();

    if (decisao == DecisaoAtendimento.recusar) {
      if (obs.isEmpty) {
        return ResultadoOperacao(
          sucesso: false,
          mensagem: "Por favor, preencha o motivo da recusa.",
        );
      }
      novoStatus = 'recusado';
    } else if (decisao == DecisaoAtendimento.aprovarParcial) {
      obs = obs.isEmpty
          ? 'Aprovado parcialmente por falta de insumos.'
          : 'Aprovado parcialmente: $obs';
    } else {
      obs = obs.isEmpty
          ? 'Aprovado totalmente: Pedido enviado para separação.'
          : 'Aprovado totalmente: $obs';
    }

    return await atualizarStatusDetalhado(
      pedidoId: pedidoId,
      novoStatus: novoStatus,
      observacao: obs,
    );
  }

  /// Procura a rota/motoboy ideal na coleção 'rotas_fixas' através do RotaRepository
  Future<ResultadoOperacao> encaminharParaEntrega({
    required String pedidoId,
    required Map<String, dynamic> pedidoData,
  }) async {
    final clinicaId = (pedidoData['clinicaId'] ?? '').toString().trim();
    final clinicaNome = (pedidoData['clinicaNome'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final laboratorioId = (pedidoData['laboratorioId'] ?? '').toString().trim();

    try {
      // 1. Busca rotas ativas através do RotaRepository (na coleção 'rotas_fixas')
      final List<RotaModel> rotasAtivas = await _rotaRepository
          .buscarRotasAtivas(laboratorioId);

      RotaModel? rotaEncontrada;

      // 2. Realiza o cruzamento insensível a maiúsculas/minúsculas entre paradas e clínica
      for (var rota in rotasAtivas) {
        final atendeClinica = rota.paradas.any((parada) {
          final pClinicaId = parada.clinicaId.trim();
          final pNomeClinica = parada.nomeClinica.trim().toLowerCase();

          final matchId = clinicaId.isNotEmpty && pClinicaId == clinicaId;
          final matchNome =
              clinicaNome.isNotEmpty &&
              (pNomeClinica == clinicaNome ||
                  pNomeClinica.contains(clinicaNome) ||
                  clinicaNome.contains(pNomeClinica));

          return matchId || matchNome;
        });

        if (atendeClinica) {
          rotaEncontrada = rota;
          break;
        }
      }

      // 3. Fallback: Se não encontrar uma específica para a clínica, seleciona a primeira rota ativa disponível
      rotaEncontrada ??= rotasAtivas.isNotEmpty ? rotasAtivas.first : null;

      if (rotaEncontrada == null) {
        return ResultadoOperacao(
          sucesso: false,
          mensagem: "⚠️ Nenhuma rota/motoboy ativo encontrado no sistema!",
        );
      }

      const novoStatus = 'aguardando_coleta';
      final obs =
          'Separação concluída. Encaminhado para o entregador ${rotaEncontrada.nomeEntregador}.';

      return await atualizarStatusDetalhado(
        pedidoId: pedidoId,
        novoStatus: novoStatus,
        observacao: obs,
        entregadorId: rotaEncontrada.entregadorId,
        nomeEntregador: rotaEncontrada.nomeEntregador,
      );
    } catch (e) {
      return ResultadoOperacao(
        sucesso: false,
        mensagem: "Erro ao encaminhar entrega: $e",
      );
    }
  }

  // --- FORMATAÇÕES VISUAIS E DATAS ---

  String formatarData(dynamic data) {
    if (data == null) return '';
    DateTime dt;
    if (data is Timestamp) {
      dt = data.toDate();
    } else if (data is String) {
      dt = DateTime.tryParse(data) ?? DateTime.now();
    } else {
      return '';
    }
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final ano = dt.year.toString();
    final hora = dt.hour.toString().padLeft(2, '0');
    final minuto = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano $hora:$minuto';
  }

  String formatarStatusAmigavel(String status) {
    switch (status.toLowerCase().trim()) {
      case 'em_separacao':
      case 'em separação':
      case 'aprovado':
      case 'aprovado_parcialmente':
      case 'aprovado parcialmente':
        return 'Em Separação';
      case 'aguardando_coleta':
      case 'aguardando_entregador':
      case 'aguardando entregador':
        return 'Aguardando Entregador';
      case 'em_transito':
      case 'saiu_para_entrega':
        return 'Em Trânsito / Rota';
      case 'recusado':
      case 'recusado / cancelado':
      case 'cancelado':
        return 'Recusado / Cancelado';
      case 'entregue':
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      default:
        return 'Pendente / Análise';
    }
  }

  Map<String, dynamic> obterEstiloStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'recusado':
      case 'recusado / cancelado':
      case 'cancelado':
        return {
          'label': 'Recusado / Cancelado',
          'cor': const Color(0xFFE53935),
          'bgBadge': const Color(0xFFFFEBEE),
          'borderBadge': const Color(0xFFFFCDD2),
          'bgIcon': const Color(0xFFFFEBEE),
          'icon': Icons.cancel_outlined,
        };
      case 'entregue':
      case 'concluido':
      case 'concluído':
        return {
          'label': 'Concluído',
          'cor': const Color(0xFF2E7D32),
          'bgBadge': const Color(0xFFE8F5E9),
          'borderBadge': const Color(0xFFA5D6A7),
          'bgIcon': const Color(0xFFE8F5E9),
          'icon': Icons.check_circle_outline,
        };
      case 'aguardando_coleta':
      case 'aguardando_entregador':
      case 'aguardando entregador':
        return {
          'label': 'Aguardando Entregador',
          'cor': const Color(0xFFED6C02),
          'bgBadge': const Color(0xFFFFF4E5),
          'borderBadge': const Color(0xFFFFE0B2),
          'bgIcon': const Color(0xFFFFF4E5),
          'icon': Icons.two_wheeler_rounded,
        };
      case 'em_separacao':
      case 'em separação':
      case 'aprovado':
      case 'aprovado_parcialmente':
      case 'aprovado parcialmente':
        return {
          'label': 'Em Separação',
          'cor': const Color(0xFF1976D2),
          'bgBadge': const Color(0xFFE3F2FD),
          'borderBadge': const Color(0xFF90CAF9),
          'bgIcon': const Color(0xFFE3F2FD),
          'icon': Icons.widgets_outlined,
        };
      default:
        return {
          'label': 'Pendente / Análise',
          'cor': const Color(0xFFE65100),
          'bgBadge': const Color(0xFFFFF3E0),
          'borderBadge': const Color(0xFFFFCC80),
          'bgIcon': const Color(0xFFFFF3E0),
          'icon': Icons.pending_actions_rounded,
        };
    }
  }
}
