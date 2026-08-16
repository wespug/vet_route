import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class DirecionamentoColetasController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  // --- ESTADOS REATIVOS ---
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  // Agrupamento da Agenda (Aba 1)
  final ValueNotifier<List<ChamadoColetaModel>> coletasAtrasadas =
      ValueNotifier([]);
  final ValueNotifier<List<ChamadoColetaModel>> coletasHoje = ValueNotifier([]);
  final ValueNotifier<List<ChamadoColetaModel>> coletasFuturas = ValueNotifier(
    [],
  );

  // Histórico Concluído (Aba 2)
  final ValueNotifier<List<ChamadoColetaModel>> coletasConcluidas =
      ValueNotifier([]);

  /// Escuta em tempo real todas as coletas vinculadas ao entregador (ou todas caso seja visão de Admin)
  void escutarColetasDoEntregador({String? entregadorId}) {
    isLoading.value = true;
    _subscription?.cancel();

    Query query = _db.collection('chamados_coleta');
    if (entregadorId != null && entregadorId.isNotEmpty) {
      query = query.where('entregadorId', isEqualTo: entregadorId);
    }

    _subscription = query.snapshots().listen((snapshot) {
      final List<ChamadoColetaModel> atrasadas = [];
      final List<ChamadoColetaModel> hoje = [];
      final List<ChamadoColetaModel> futuras = [];
      final List<ChamadoColetaModel> concluidas = [];

      final agora = DateTime.now();
      final hojeInicio = DateTime(agora.year, agora.month, agora.day);
      final hojeFim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

      for (var doc in snapshot.docs) {
        try {
          final coleta = ChamadoColetaModel.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
          final statusLower = coleta.status.toLowerCase();

          // 💡 REGRA DE NEGÓCIO 3 & 4: Separação de Status Concluídos vs Agenda Ativa
          final isFinalizado =
              statusLower == 'entregue' ||
              statusLower == 'concluído' ||
              statusLower == 'concluido' ||
              statusLower == 'finalizada' ||
              statusLower == 'cancelado';

          if (isFinalizado) {
            concluidas.add(coleta);
          } else {
            // Apenas "A pegar" ou "Em andamento"
            final dataAg = coleta.dataAgendamento;

            if (dataAg.isBefore(hojeInicio)) {
              atrasadas.add(coleta); // 🔴 Ficou para trás
            } else if (dataAg.isAfter(hojeFim)) {
              futuras.add(coleta); // 📅 Próximos dias
            } else {
              hoje.add(coleta); // 🟢 Hoje
            }
          }
        } catch (e) {
          debugPrint("Erro ao ler coleta no direcionamento: $e");
        }
      }

      // Ordenação: Emergências e horários mais antigos primeiro
      int comparar(ChamadoColetaModel a, ChamadoColetaModel b) {
        if (a.isEmergencia && !b.isEmergencia) return -1;
        if (!a.isEmergencia && b.isEmergencia) return 1;
        return a.dataAgendamento.compareTo(b.dataAgendamento);
      }

      atrasadas.sort(comparar);
      hoje.sort(comparar);
      futuras.sort(comparar);
      concluidas.sort((a, b) => b.dataAgendamento.compareTo(a.dataAgendamento));

      coletasAtrasadas.value = atrasadas;
      coletasHoje.value = hoje;
      coletasFuturas.value = futuras;
      coletasConcluidas.value = concluidas;
      isLoading.value = false;
    });
  }

  void dispose() {
    _subscription?.cancel();
    isLoading.dispose();
    coletasAtrasadas.dispose();
    coletasHoje.dispose();
    coletasFuturas.dispose();
    coletasConcluidas.dispose();
  }
}
