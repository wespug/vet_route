import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class ChamadoColetaController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    _db
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: clinicaId)
        .snapshots()
        .listen((snapshot) {
          final chamados = snapshot.docs
              .map((doc) => ChamadoColetaModel.fromMap(doc.id, doc.data()))
              .toList();

          final dataAtual = DateTime.now();
          final List<ChamadoColetaModel> listaHoje = [];
          final List<ChamadoColetaModel> listaPassados = [];

          // Triagem Inteligente baseada no Agendamento
          for (var c in chamados) {
            DateTime dataReferencia = c.dataAgendamento;

            bool isHoje =
                dataReferencia.year == dataAtual.year &&
                dataReferencia.month == dataAtual.month &&
                dataReferencia.day == dataAtual.day;

            bool isAtivo =
                c.status == 'Aguardando Entregador' ||
                c.status == 'Em Trânsito';
            bool isFuturo = dataReferencia.isAfter(dataAtual) && !isHoje;

            // Vai para a Aba Principal se for para hoje, se for no futuro, ou se estiver ativo pendente.
            if (isHoje || isAtivo || isFuturo) {
              listaHoje.add(c);
            } else {
              listaPassados.add(c);
            }
          }

          // Ordenação Principal: Emergências primeiro, depois ordem de agendamento (o mais cedo primeiro)
          listaHoje.sort((a, b) {
            if (a.isEmergencia && !b.isEmergencia) return -1;
            if (!a.isEmergencia && b.isEmergencia) return 1;
            return a.dataAgendamento.compareTo(b.dataAgendamento);
          });

          // Histórico: Do mais recente para o mais antigo
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
    isLoading.dispose();
    chamadosHoje.dispose();
    chamadosPassados.dispose();
    laboratorios.dispose();
  }
}
