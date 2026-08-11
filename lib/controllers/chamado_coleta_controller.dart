import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class ChamadoColetaController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _subscriptionCombinada;

  // --- ESTADOS REATIVOS ---
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<ChamadoColetaModel>> chamadosHoje = ValueNotifier(
    [],
  );
  final ValueNotifier<List<ChamadoColetaModel>> chamadosPassados =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> laboratorios = ValueNotifier(
    [],
  );

  // =========================================================================
  // 🟢 MÉTODOS DE ROTEAMENTO E REGRAS DE NEGÓCIO
  // =========================================================================

  void carregarChamados(String clinicaId) {
    isLoading.value = true;

    final coletasStream = _db
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots();

    final insumosStream = _db
        .collection('pedidos_insumos')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots();

    _subscriptionCombinada?.cancel();
    _subscriptionCombinada =
        Rx.combineLatest2(coletasStream, insumosStream, (
          QuerySnapshot coletasSnapshot,
          QuerySnapshot insumosSnapshot,
        ) {
          final List<ChamadoColetaModel> listaUnificada = [];

          // 3.1 Convertendo Coletas Normais
          for (var doc in coletasSnapshot.docs) {
            try {
              listaUnificada.add(
                ChamadoColetaModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              );
            } catch (e) {
              debugPrint("Erro ao ler coleta ${doc.id}:$e");
            }
          }

          // 3.2 Convertendo Pedidos de Insumo para parecerem Chamados na UI
          for (var doc in insumosSnapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;

              DateTime dataSolicitacao = DateTime.now();
              if (data['dataSolicitacao'] != null) {
                dataSolicitacao = (data['dataSolicitacao'] as Timestamp)
                    .toDate();
              }

              listaUnificada.add(
                ChamadoColetaModel(
                  id: doc.id,
                  clinicaId: data['clinicaId'] ?? '',
                  clinicaNome: data['clinicaNome'] ?? '',
                  // 💡 MÁGICA 1: Inserimos 'INSUMO_' no ID para o sistema saber abrir o modal certo!
                  laboratorioId: 'INSUMO_${data['laboratorioId'] ?? ''}',
                  // 💡 MÁGICA 2: Mostramos o NOME REAL do laboratório
                  laboratorioNome:
                      data['laboratorioNome'] ?? 'Laboratório Parceiro',
                  status: data['status'] ?? 'Pendente',
                  isEmergencia: false,
                  dataCriacao: dataSolicitacao,
                  dataAgendamento: dataSolicitacao,
                ),
              );
            } catch (e) {
              debugPrint("Erro ao ler insumo ${doc.id}:$e");
            }
          }

          return listaUnificada;
        }).listen((todosOsChamados) {
          final List<ChamadoColetaModel> listaHoje = [];
          final List<ChamadoColetaModel> listaPassados = [];

          for (var c in todosOsChamados) {
            final statusLower = c.status.toLowerCase();

            // 💡 REGRA DE NEGÓCIO: Se estiver entregue, concluído, cancelado, recusado ou finalizada, vai para o Histórico / Encerrados
            final isHistorico =
                statusLower == 'entregue' ||
                statusLower == 'concluído' ||
                statusLower == 'cancelado' ||
                statusLower == 'recusado' ||
                statusLower == 'finalizada';

            if (isHistorico) {
              listaPassados.add(c);
            } else {
              listaHoje.add(c);
            }
          }

          // Ordenação da aba de Ativas (Emergências primeiro, depois por data)
          listaHoje.sort((a, b) {
            if (a.isEmergencia && !b.isEmergencia) return -1;
            if (!a.isEmergencia && b.isEmergencia) return 1;
            return a.dataAgendamento.compareTo(b.dataAgendamento);
          });

          // Ordenação da aba de Histórico (Mais recentes primeiro)
          listaPassados.sort(
            (a, b) => b.dataAgendamento.compareTo(a.dataAgendamento),
          );

          chamadosHoje.value = listaHoje;
          chamadosPassados.value = listaPassados;
          isLoading.value = false;
        });
  }

  Future<void> carregarLaboratorios() async {
    try {
      final snapshot = await _db.collection('laboratorios').get();
      final labs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      laboratorios.value = labs;
    } catch (e) {
      debugPrint('Erro ao carregar laboratórios: $e');
    }
  }

  Future<bool> criarChamado(ChamadoColetaModel chamado) async {
    try {
      await _db.collection('chamados_coleta').add(chamado.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao criar chamado: $e');
      return false;
    }
  }

  void dispose() {
    _subscriptionCombinada?.cancel();
    isLoading.dispose();
    chamadosHoje.dispose();
    chamadosPassados.dispose();
    laboratorios.dispose();
  }
}
