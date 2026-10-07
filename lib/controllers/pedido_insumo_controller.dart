import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';
import 'package:vet_route/models/rota_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/endereco_model.dart';
import 'package:vet_route/models/clinica_model.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PedidoInsumoModel> pedidos = [];

  // 🔹 Listas específicas para a visão da Clínica (Separadas por status)
  List<PedidoInsumoModel> pedidosAtivos = [];
  List<PedidoInsumoModel> pedidosEncerrados = [];

  bool carregando = true;

  // 🔹 Notifiers para suprir a listagem de laboratórios no modal de insumos
  final ValueNotifier<List<Laboratorio>> laboratorios =
      ValueNotifier<List<Laboratorio>>([]);
  final ValueNotifier<bool> isLoadingLab = ValueNotifier<bool>(false);

  // ===========================================================================
  // 0. SUPORTE AO MODAL DE PEDIR INSUMOS (LABORATÓRIOS E CRIAÇÃO)
  // ===========================================================================

  /// Carrega a lista de laboratórios parceiros para o dropdown do modal
  Future<void> carregarLaboratorios() async {
    isLoadingLab.value = true;
    try {
      final snapshot = await _firestore.collection('laboratorios').get();
      final lista = snapshot.docs
          .map((doc) => Laboratorio.fromFirestore(doc))
          .toList();
      laboratorios.value = lista;
    } catch (e) {
      debugPrint("Erro ao carregar laboratórios: $e");
    } finally {
      isLoadingLab.value = false;
    }
  }

  /// Cria o pedido de insumos no Firestore acionado pelo modal da clínica
  /// Cria o pedido de insumos no Firestore acionado pelo modal da clínica
  Future criarPedido({
    required Clinica clinica, // 💡 Agora recebe o objeto completo
    required Laboratorio laboratorio, // 💡 Agora recebe o objeto completo
    required String usuarioSolicitante,
    required List itens,
  }) async {
    try {
      final docRef = _firestore.collection('pedidos_insumos').doc();
      final dataAtual = DateTime.now().toIso8601String();

      final Map itemHistorico = {
        'status': 'pendente',
        'data': dataAtual,
        'observacao': 'Pedido de insumos criado pela clínica.',
        'usuario': usuarioSolicitante,
      };

      await docRef.set({
        'id': docRef.id,
        'clinicaId': clinica.id,
        'clinicaNome': clinica.nome,
        'laboratorioId': laboratorio.id,
        'laboratorioNome': laboratorio.nome,
        // 💡 A MÁGICA ACONTECE AQUI: Salvando a "fotografia" com os endereços!
        'clinicaOrigem': clinica.toMap(),
        'laboratorioDestino': laboratorio.toMap(),
        'status': 'pendente',
        'itens': itens,
        'dataCriacao': FieldValue.serverTimestamp(),
        'usuarioSolicitante': usuarioSolicitante,
        'historico': [itemHistorico],
      });

      return true;
    } catch (e) {
      debugPrint("Erro ao criar pedido de insumo: $e");
      return false;
    }
  }

  // ===========================================================================
  // 1. ESCUTA E FLUXO DO LADO DA CLÍNICA (MODAL DE DETALHES E LISTAGEM)
  // ===========================================================================

  /// Escuta em tempo real os pedidos feitos por uma Clínica específica (divide ativos e encerrados)
  void escutarPedidosPorClinica(String clinicaId) {
    carregando = true;
    notifyListeners();

    _firestore
        .collection('pedidos_insumos')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots()
        .listen(
          (snapshot) {
            final todos = snapshot.docs
                .map((doc) => PedidoInsumoModel.fromFirestore(doc))
                .toList();

            List<PedidoInsumoModel> ativos = [];
            List<PedidoInsumoModel> encerrados = [];

            for (var p in todos) {
              if (p.isRecusadoOuCancelado ||
                  p.status.toLowerCase() == 'entregue' ||
                  p.status.toLowerCase() == 'concluído' ||
                  p.status.toLowerCase() == 'concluido') {
                encerrados.add(p);
              } else {
                ativos.add(p);
              }
            }

            pedidosAtivos = ativos;
            pedidosEncerrados = encerrados;
            pedidos = todos;
            carregando = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Erro ao escutar pedidos da clínica: $e");
            carregando = false;
            notifyListeners();
          },
        );
  }

  /// Stream em tempo real do documento específico para a Modal da Clínica
  Stream<PedidoInsumoModel?> obterStreamPedido(String docIdLimpo) {
    return _firestore
        .collection('pedidos_insumos')
        .doc(docIdLimpo)
        .snapshots()
        .map((doc) => doc.exists ? PedidoInsumoModel.fromFirestore(doc) : null);
  }

  /// Cancela o pedido de insumos registrando a ação no histórico
  Future<void> cancelarPedido({
    required String docIdLimpo,
    required String chamadoIdOriginal,
    required String usuarioLogado,
  }) async {
    final batch = _firestore.batch();
    final dataAtual = DateTime.now().toIso8601String();

    final Map<String, dynamic> itemHistorico = {
      'status': 'cancelado',
      'data': dataAtual,
      'observacao': 'Pedido cancelado pela clínica solicitante.',
      'usuario': usuarioLogado,
    };

    final docInsumoRef = _firestore
        .collection('pedidos_insumos')
        .doc(docIdLimpo);
    batch.set(docInsumoRef, {
      'status': 'cancelado',
      'dataAtualizacao': FieldValue.serverTimestamp(),
      'usuarioCancelamento': usuarioLogado,
      'justificativaLab': 'Pedido cancelado pela clínica solicitante.',
      'historico': FieldValue.arrayUnion([itemHistorico]),
    }, SetOptions(merge: true));

    if (chamadoIdOriginal.isNotEmpty) {
      final docChamadoRef = _firestore
          .collection('chamados_coleta')
          .doc(chamadoIdOriginal);
      final docSnapshot = await docChamadoRef.get();

      if (docSnapshot.exists) {
        batch.update(docChamadoRef, {
          'status': 'cancelado',
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  // ===========================================================================
  // 2. ESCUTA E FLUXO DO LADO DO LABORATÓRIO (LISTAGEM E PAINEL)
  // ===========================================================================

  /// Escuta pedidos em tempo real vinculados a um laboratório
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

  Future<ResultadoOperacao> atualizarStatusDetalhado({
    required String pedidoId,
    required String novoStatus,
    required String observacao,
    String? entregadorId,
    String? nomeEntregador,
    String? veiculo, // 💡 Novo campo
    String? placa, // 💡 Novo campo
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
      if (veiculo != null) itemHistorico['veiculo'] = veiculo;
      if (placa != null) itemHistorico['placa'] = placa;

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

  // 💡 ATUALIZADO: Aceita os itens parciais para gravação!
  Future<ResultadoOperacao> processarDecisaoModal({
    required String pedidoId,
    required DecisaoAtendimento decisao,
    required String motivoOuObservacao,
    List<Map<String, dynamic>>? itensAtualizados,
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

    // Grava as quantidades parciais no Firestore se fornecidas
    if (decisao == DecisaoAtendimento.aprovarParcial &&
        itensAtualizados != null) {
      try {
        await _firestore.collection('pedidos_insumos').doc(pedidoId).update({
          'itens': itensAtualizados,
        });
      } catch (e) {
        debugPrint("Erro ao atualizar os itens parciais: $e");
      }
    }

    return await atualizarStatusDetalhado(
      pedidoId: pedidoId,
      novoStatus: novoStatus,
      observacao: obs,
    );
  }

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
    final chamadoIdOriginal = (pedidoData['chamadoId'] ?? '').toString().trim();

    try {
      final List<RotaModel> rotasAtivas = await _rotaRepository
          .buscarRotasAtivas(laboratorioId);

      RotaModel? rotaEncontrada;

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

      // 💡 MEGA CORREÇÃO: Resgatar Veículo e Placa no perfil do entregador
      String? veiculoInjetar;
      String? placaInjetar;
      try {
        final entregadorDoc = await _firestore
            .collection('usuarios')
            .doc(rotaEncontrada.entregadorId)
            .get();
        if (entregadorDoc.exists) {
          final dadosEntregador = entregadorDoc.data()!;

          final rawVeiculo = dadosEntregador['veiculo'];
          final rawPlaca = dadosEntregador['placa'];

          // 1. Se o veículo foi salvo como um Objeto (Map) no Firestore
          if (rawVeiculo is Map) {
            veiculoInjetar =
                (rawVeiculo['modelo'] ??
                        rawVeiculo['marca'] ??
                        'Veículo Registrado')
                    .toString();
            placaInjetar = (rawVeiculo['placa'] ?? rawPlaca)?.toString();
          }
          // 2. Se foi salvo como um texto simples (String)
          else {
            veiculoInjetar = rawVeiculo?.toString();
            placaInjetar = rawPlaca?.toString();
          }
        }
      } catch (e) {
        debugPrint(
          "Aviso: Falha ao buscar placa do entregador para insumos: $e",
        );
      }

      // Gravamos logo diretamente no documento principal de insumos para as modais lerem!
      if (veiculoInjetar != null || placaInjetar != null) {
        // 💡 O NOSSO ESPIÃO DE GRAVAÇÃO:
        debugPrint("\n====================================");
        debugPrint("🚀 A GRAVAR DADOS DO VEÍCULO NO BANCO...");
        debugPrint("Pedido ID: $pedidoId");
        debugPrint("Motoboy ID: ${rotaEncontrada.entregadorId}");
        debugPrint("Veículo a salvar: ${veiculoInjetar ?? 'Não informado'}");
        debugPrint("Placa a salvar: ${placaInjetar ?? 'Não informada'}");
        debugPrint("====================================\n");

        await _firestore.collection('pedidos_insumos').doc(pedidoId).update({
          'veiculo': veiculoInjetar ?? 'Não informado',
          'placa': placaInjetar ?? 'Não informada',
        });

        debugPrint("✅ Gravação concluída com sucesso no Firestore!");
      } else {
        debugPrint(
          "\n⚠️ AVISO: Não encontrámos veículo/placa no perfil do entregador para gravar!\n",
        );
      }

      final res = await atualizarStatusDetalhado(
        pedidoId: pedidoId,
        novoStatus: novoStatus,
        observacao: obs,
        entregadorId: rotaEncontrada.entregadorId,
        nomeEntregador: rotaEncontrada.nomeEntregador,
      );

      if (!res.sucesso) return res;

      // 💡 CORREÇÃO: Não criamos mais documento fantasma!
      // Se existir um chamado original vinculado, apenas atualizamos ele.
      if (chamadoIdOriginal.isNotEmpty) {
        await _firestore
            .collection('chamados_coleta')
            .doc(chamadoIdOriginal)
            .update({
              'entregadorId': rotaEncontrada.entregadorId,
              'nomeEntregador': rotaEncontrada.nomeEntregador,
              'status': 'aguardando_coleta',
              'atualizadoEm': FieldValue.serverTimestamp(),
            });
      }

      return ResultadoOperacao(
        sucesso: true,
        mensagem:
            "Pedido encaminhado para o entregador ${rotaEncontrada.nomeEntregador} com sucesso!",
      );
    } catch (e) {
      return ResultadoOperacao(
        sucesso: false,
        mensagem: "Erro ao encaminhar entrega: $e",
      );
    }
  }

  // ===========================================================================
  // 3. MÉTODOS DE FORMATAÇÃO E ESTILO
  // ===========================================================================

  String formatarData(dynamic data) {
    if (data == null) return '';
    DateTime dt;
    if (data is Timestamp) {
      dt = data.toDate();
    } else if (data is String) {
      dt = DateTime.tryParse(data) ?? DateTime.now();
    } else if (data is DateTime) {
      dt = data;
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
      case 'coletar_produto':
        return 'Motoboy no Local / Aguardando Coleta';
      case 'em_transporte':
        return 'Em Transporte';
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
      // 💡 ADICIONADO: A NOVA COR PARA DIFERENCIAR O "EM TRANSPORTE" (Verde escuro)
      case 'em_transporte':
        return {
          'label': 'Em Transporte',
          'cor': Colors.green.shade800,
          'bgBadge': Colors.green.shade50,
          'borderBadge': Colors.green.shade200,
          'bgIcon': Colors.green.shade50,
          'icon': Icons.local_shipping_rounded,
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
      case 'coletar_produto':
        return {
          'label': 'Motoboy no Local / Aguardando Coleta',
          'cor': Colors.purple.shade700,
          'bgBadge': Colors.purple.shade50,
          'borderBadge': Colors.purple.shade200,
          'bgIcon': Colors.purple.shade50,
          'icon': Icons.person_pin_circle_rounded,
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
