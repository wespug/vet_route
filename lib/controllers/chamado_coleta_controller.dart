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

  /// Carrega e une em tempo real os chamados de exames e pedidos de insumo da clínica
  void carregarChamados(String clinicaId) {
    if (clinicaId.isEmpty) return;

    isLoading.value = true;
    _coletasSub?.cancel();
    _insumosSub?.cancel();

    List<ItemLogisticaModel> listaColetas = [];
    List<ItemLogisticaModel> listaInsumos = [];

    void processarEAtualizar() {
      final todos = [...listaColetas, ...listaInsumos];

      // Ordena do mais recente para o mais antigo
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

    // 1. Escuta Coletas / Exames
    _coletasSub = _db
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots()
        .listen(
          (snapshot) {
            listaColetas = snapshot.docs
                .map<ItemLogisticaModel>(
                  (doc) => ItemLogisticaModel.fromChamadoColeta(doc),
                )
                .toList();
            processarEAtualizar();
          },
          onError: (e) {
            debugPrint('❌ Erro coletas: $e');
          },
        );

    // 2. Escuta Pedidos de Insumos
    _insumosSub = _db
        .collection('pedidos_insumos')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots()
        .listen(
          (snapshot) {
            listaInsumos = snapshot.docs
                .map((doc) => ItemLogisticaModel.fromPedidoInsumo(doc))
                .toList();
            processarEAtualizar();
          },
          onError: (e) {
            debugPrint('❌ Erro insumos: $e');
          },
        );
  }

  /// Carrega a lista de laboratórios
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

  /// Método mantido para compatibilidade ao criar novos chamados legados
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

  /// Cancela um item de logística (Exame ou Insumo) e registra no histórico
  Future<void> cancelarItem(
    ItemLogisticaModel item,
    String usuarioLogado,
  ) async {
    try {
      isLoading.value = true;

      // Resolve a coleção correta de forma simples e livre de erros de compilação
      final String colecao = item.isInsumo
          ? 'pedidos_insumos'
          : 'chamados_coleta';

      // Cria o objeto de histórico diretamente como Map para evitar conflitos de importação
      final Map<String, dynamic> novoLog = {
        'status': 'Cancelado',
        'usuario': usuarioLogado.isNotEmpty ? usuarioLogado : 'Clínica',
        'data': Timestamp.now(),
        'observacao': 'Pedido cancelado pelo usuário através do painel',
      };

      // Atualiza o documento no Firestore em tempo real
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

  void dispose() {
    _coletasSub?.cancel();
    _insumosSub?.cancel();
    isLoading.dispose();
    itensAtivos.dispose();
    itensHistorico.dispose();
    laboratorios.dispose();
  }
}
