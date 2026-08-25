import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/models/rota_model.dart';

class DirecionamentoColetasController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _subColetas;
  StreamSubscription? _subRota;

  // --- ESTADOS REATIVOS ---
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  // Guardamos o mapa de horários/turnos previstos por clínica { clinicaId: horarioPrevisto }
  final ValueNotifier<Map<String, String>> mapaHorariosClinica = ValueNotifier(
    {},
  );

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

  /// Carrega as rotas ativas do entregador e filtra estritamente as coletas das clínicas pertencentes
  void escutarColetasDoEntregador({required String entregadorId}) {
    isLoading.value = true;
    _subColetas?.cancel();
    _subRota?.cancel();

    // 1. OUVIR A ROTA ATIVA DO ENTREGADOR
    _subRota = _db
        .collection('rotas')
        .where('entregadorId', isEqualTo: entregadorId)
        .where('ativa', isEqualTo: true)
        .snapshots()
        .listen((rotaSnapshot) {
          final Set<String> clinicasDoEntregador = {};
          final Map<String, String> horariosPorClinica = {};

          for (var doc in rotaSnapshot.docs) {
            final rota = RotaModel.fromFirestore(doc);
            for (var parada in rota.paradas) {
              clinicasDoEntregador.add(parada.clinicaId);
              horariosPorClinica[parada.clinicaId] = parada.horarioPrevisto;
            }
          }

          mapaHorariosClinica.value = horariosPorClinica;

          // Se o entregador não tem rotas/clínicas associadas, limpa a tela
          if (clinicasDoEntregador.isEmpty) {
            coletasAtrasadas.value = [];
            coletasHoje.value = [];
            coletasFuturas.value = [];
            coletasConcluidas.value = [];
            isLoading.value = false;
            return;
          }

          // 2. BUSCAR APENAS AS COLETAS QUE PERTENCEM ÀS CLÍNICAS DA ROTA DELE
          _subColetas?.cancel();
          _subColetas = _db.collection('chamados_coleta').snapshots().listen((
            coletaSnapshot,
          ) {
            final List<ChamadoColetaModel> atrasadas = [];
            final List<ChamadoColetaModel> hoje = [];
            final List<ChamadoColetaModel> futuras = [];
            final List<ChamadoColetaModel> concluidas = [];

            final agora = DateTime.now();
            final hojeInicio = DateTime(agora.year, agora.month, agora.day);
            final hojeFim = DateTime(
              agora.year,
              agora.month,
              agora.day,
              23,
              59,
              59,
            );

            for (var doc in coletaSnapshot.docs) {
              try {
                final coleta = ChamadoColetaModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                );

                // 🎯 FILTRO ESTRITO: Pertence à Rota do Entregador ou está atribuído diretamente
                final pertenceRuta =
                    clinicasDoEntregador.contains(coleta.clinicaId) ||
                    coleta.entregadorId == entregadorId;

                if (!pertenceRuta) continue;

                final statusLower = coleta.status.toLowerCase();
                final isFinalizado =
                    statusLower == 'entregue' ||
                    statusLower == 'concluído' ||
                    statusLower == 'concluido' ||
                    statusLower == 'finalizada' ||
                    statusLower == 'cancelado';

                if (isFinalizado) {
                  concluidas.add(coleta);
                } else {
                  final dataAg = coleta.dataAgendamento;

                  if (dataAg.isBefore(hojeInicio)) {
                    atrasadas.add(coleta);
                  } else if (dataAg.isAfter(hojeFim)) {
                    futuras.add(coleta);
                  } else {
                    hoje.add(coleta);
                  }
                }
              } catch (e) {
                debugPrint("Erro ao ler coleta: $e");
              }
            }

            // 🎯 ORDENAÇÃO POR ANTIGUIDADE + TURNO / HORÁRIO PREVISTO DA PARADA
            int compararColetas(ChamadoColetaModel a, ChamadoColetaModel b) {
              // 1º Emergências têm prioridade absoluta
              if (a.isEmergencia && !b.isEmergencia) return -1;
              if (!a.isEmergencia && b.isEmergencia) return 1;

              // 2º Ordenação pela Data de Agendamento (Mais antigas primeiro)
              final compData = a.dataAgendamento.compareTo(b.dataAgendamento);
              if (compData != 0) return compData;

              // 3º Ordenação pelo Turno/Horário Previsto da Parada na Rota
              final horarioA = horariosPorClinica[a.clinicaId] ?? '99:99';
              final horarioB = horariosPorClinica[b.clinicaId] ?? '99:99';
              return horarioA.compareTo(horarioB);
            }

            atrasadas.sort(compararColetas);
            hoje.sort(compararColetas);
            futuras.sort(compararColetas);
            concluidas.sort(
              (a, b) => b.dataAgendamento.compareTo(a.dataAgendamento),
            );

            coletasAtrasadas.value = atrasadas;
            coletasHoje.value = hoje;
            coletasFuturas.value = futuras;
            coletasConcluidas.value = concluidas;
            isLoading.value = false;
          });
        });
  }

  void dispose() {
    _subColetas?.cancel();
    _subRota?.cancel();
    isLoading.dispose();
    mapaHorariosClinica.dispose();
    coletasAtrasadas.dispose();
    coletasHoje.dispose();
    coletasFuturas.dispose();
    coletasConcluidas.dispose();
  }
}
