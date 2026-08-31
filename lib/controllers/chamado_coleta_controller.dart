import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/models/endereco_model.dart';
import 'package:vet_route/models/item_logistica_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class ChamadoColetaController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<ItemLogisticaModel>> itensAtivos =
      ValueNotifier<List<ItemLogisticaModel>>([]);
  final ValueNotifier<List<ItemLogisticaModel>> itensHistorico =
      ValueNotifier<List<ItemLogisticaModel>>([]);
  final ValueNotifier<List<Laboratorio>> laboratorios =
      ValueNotifier<List<Laboratorio>>([]);

  StreamSubscription<QuerySnapshot>? _coletasSub;
  StreamSubscription<QuerySnapshot>? _insumosSub;

  void carregarChamados(String clinicaId) {
    if (clinicaId.isEmpty) return;

    isLoading.value = true;
    _coletasSub?.cancel();
    _insumosSub?.cancel();

    List<ItemLogisticaModel> listaColetas = [];
    List<ItemLogisticaModel> listaInsumos = [];

    void processarEAtualizar() {
      final todos = [...listaColetas, ...listaInsumos];

      todos.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));

      final List<ItemLogisticaModel> ativas = [];
      final List<ItemLogisticaModel> historico = [];

      for (var item in todos) {
        final st = item.status.toLowerCase();
        final eEncerrado =
            st == 'entregue' ||
            st == 'concluído' ||
            st == 'concluido' ||
            st == 'cancelado' ||
            st == 'recusado' ||
            st == 'finalizada';

        if (eEncerrado) {
          historico.add(item);
        } else {
          ativas.add(item);
        }
      }

      itensAtivos.value = ativas;
      itensHistorico.value = historico;
      isLoading.value = false;
    }

    // 1. Escuta Coletas (Ignorando os fantasmas de insumo injetados)
    _coletasSub = _db
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots()
        .listen((snapshot) {
          listaColetas = snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final isEspelhoInsumo =
                    data['possuiInsumo'] == true ||
                    data['tipo']?.toString().toLowerCase() == 'insumo';
                return !isEspelhoInsumo;
              })
              .map<ItemLogisticaModel>(
                (doc) => ItemLogisticaModel.fromChamadoColeta(doc),
              )
              .toList();
          processarEAtualizar();
        }, onError: (e) => debugPrint('❌ Erro coletas: $e'));

    // 2. Escuta Pedidos de Insumos
    _insumosSub = _db
        .collection('pedidos_insumos')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots()
        .listen((snapshot) {
          listaInsumos = snapshot.docs
              .map((doc) => ItemLogisticaModel.fromPedidoInsumo(doc))
              .toList();
          processarEAtualizar();
        }, onError: (e) => debugPrint('❌ Erro insumos: $e'));
  }

  Future<void> carregarLaboratorios() async {
    try {
      final snapshot = await _db.collection('laboratorios').get();
      final lista = snapshot.docs.map((doc) {
        final data = doc.data();
        return Laboratorio(
          id: doc.id,
          nome: data['nome'] ?? '',
          email: data['email'] ?? '',
          telefone: data['telefone'] ?? '',
          cnpj: data['cnpj'] ?? '',
          endereco: Endereco.fromMap(data['endereco'] ?? {}),
        );
      }).toList();

      laboratorios.value = lista;
    } catch (e) {
      debugPrint('❌ Erro ao carregar laboratórios: $e');
    }
  }

  Future<bool> criarChamado(ChamadoColetaModel chamado) async {
    try {
      isLoading.value = true;
      await _db.collection('chamados_coleta').add({
        ...chamado.toMap(),
        'historicoLogs': [
          {
            'status': chamado.status,
            'usuario': 'Clínica',
            'data': Timestamp.now(),
            'observacao': 'Chamado criado na plataforma',
          },
        ],
      });
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao criar chamado: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelarItem(
    ItemLogisticaModel item,
    String usuarioLogado,
  ) async {
    try {
      isLoading.value = true;
      final String colecao = item.isInsumo
          ? 'pedidos_insumos'
          : 'chamados_coleta';

      final Map<String, dynamic> novoLog = {
        'status': 'Cancelado',
        'usuario': usuarioLogado.isNotEmpty ? usuarioLogado : 'Clínica',
        'data': Timestamp.now(),
        'observacao': 'Pedido cancelado pelo usuário através do painel',
      };

      await _db.collection(colecao).doc(item.id).update({
        'status': 'Cancelado',
        'historicoLogs': FieldValue.arrayUnion([novoLog]),
        'dataCancelamento': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao cancelar o item: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 💡 NOVO: Motor Central de Roteamento Preditivo (MVC)
  Future<String> agendarColetaComRoteamento({
    required String clinicaId,
    required String clinicaNome,
    required String laboratorioId,
    required String laboratorioNome,
    required bool isEmergencia,
    required DateTime dataDesejada,
    required String observacao,
    required String usuarioLogado,
  }) async {
    try {
      isLoading.value = true;

      // Consulta direta baseada na coleção correta corrigida
      final rotasSnapshot = await _db
          .collection('rotas_fixas')
          .where('laboratorioId', isEqualTo: laboratorioId)
          .where('ativa', isEqualTo: true)
          .get();

      String? motoboyId;
      String? motoboyNome;
      List<int> diasOperacao = [1, 2, 3, 4, 5];

      for (var doc in rotasSnapshot.docs) {
        final rotaData = doc.data();
        final paradas = (rotaData['paradas'] as List<dynamic>?) ?? [];

        final atendeClinica = paradas.any((p) {
          final pMap = p as Map<String, dynamic>;
          final pClinicaId = (pMap['clinicaId'] ?? '').toString().trim();
          return pClinicaId == clinicaId;
        });

        if (atendeClinica) {
          motoboyId = rotaData['entregadorId'];
          motoboyNome = rotaData['nomeEntregador'];
          if (rotaData['diasOperacao'] != null) {
            diasOperacao = List<int>.from(rotaData['diasOperacao']);
          }
          break;
        }
      }

      if (motoboyId == null && rotasSnapshot.docs.isNotEmpty) {
        final primeiraRota = rotasSnapshot.docs.first.data();
        motoboyId = primeiraRota['entregadorId'];
        motoboyNome = primeiraRota['nomeEntregador'];
        if (primeiraRota['diasOperacao'] != null) {
          diasOperacao = List<int>.from(primeiraRota['diasOperacao']);
        }
      }

      DateTime dataAjustada = dataDesejada;
      bool dataFoiAjustada = false;

      if (motoboyId != null && diasOperacao.isNotEmpty) {
        int limiteBusca = 0;
        while (!diasOperacao.contains(dataAjustada.weekday) &&
            limiteBusca < 14) {
          dataAjustada = dataAjustada.add(const Duration(days: 1));
          dataFoiAjustada = true;
          limiteBusca++;
        }
      }

      final bool temMotoboy = motoboyId != null && motoboyId.isNotEmpty;
      final String statusInicial = temMotoboy
          ? 'aguardando_coleta'
          : 'Pendente';

      String obsHistorico =
          'Coleta agendada na plataforma. Aguardando disponibilidade de entregador.';

      if (temMotoboy) {
        if (dataFoiAjustada) {
          final strNovaData =
              "${dataAjustada.day.toString().padLeft(2, '0')}/${dataAjustada.month.toString().padLeft(2, '0')}";
          obsHistorico =
              'Coleta agendada. Data ajustada automaticamente para o próximo dia útil da rota ($strNovaData) do entregador $motoboyNome.';
        } else {
          obsHistorico =
              'Coleta agendada. Rota automática atribuída para o entregador $motoboyNome.';
        }
      }

      final payload = {
        'clinicaId': clinicaId,
        'clinicaNome': clinicaNome,
        'laboratorioId': laboratorioId,
        'laboratorioNome': laboratorioNome,
        'status': statusInicial,
        'isUrgencia': isEmergencia,
        'isEmergencia': isEmergencia,
        'tipo': 'Exame',
        'possuiInsumo': false,
        'dataCriacao': FieldValue.serverTimestamp(),
        'dataAgendamento': Timestamp.fromDate(dataAjustada),
        'observacao': observacao,
        'usuarioCriador': usuarioLogado,
        'historicoLogs': [
          {
            'status': statusInicial,
            'usuario': usuarioLogado,
            'data': Timestamp.now(),
            'observacao': obsHistorico,
          },
        ],
      };

      if (temMotoboy) {
        payload['entregadorId'] = motoboyId!;
        payload['nomeEntregador'] = motoboyNome!;
      }

      await _db.collection('chamados_coleta').add(payload);

      if (temMotoboy) {
        return dataFoiAjustada
            ? "Coleta confirmada para o próximo dia útil da rota."
            : "Coleta despachada para o entregador!";
      } else {
        return "Coleta solicitada! Aguardando alocação de entregador.";
      }
    } catch (e) {
      debugPrint("Erro no MVC de agendamento: $e");
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _coletasSub?.cancel();
    _insumosSub?.cancel();
    isLoading.dispose();
    itensAtivos.dispose();
    itensHistorico.dispose();
    laboratorios.dispose();
  }
}
