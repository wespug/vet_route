import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/coleta_model.dart';

class GestaoExamesLabController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  List<Coleta> aguardando = [];
  List<Coleta> emRota = [];
  List<Coleta> recebidosHoje = [];
  List<Coleta> historico = [];

  // Nova lista para alimentar o Dropdown da View
  List<Map<String, String>> motoboysParceiros = [];

  bool isLoading = true;

  void iniciarEscuta(String laboratorioId) {
    isLoading = true;
    notifyListeners();

    // Dispara a busca de motoboys paralelamente à escuta de exames
    _carregarMotoboysParceiros(laboratorioId);

    _sub?.cancel();
    _sub = _db
        .collection('chamados_coleta')
        .where('laboratorioId', isEqualTo: laboratorioId)
        .where('tipo', isEqualTo: 'Exame')
        .snapshots()
        .listen(
          (snapshot) {
            final hoje = DateTime.now();

            final List<Coleta> tempAguardando = [];
            final List<Coleta> tempEmRota = [];
            final List<Coleta> tempRecebidosHoje = [];
            final List<Coleta> tempHistorico = [];

            for (var doc in snapshot.docs) {
              final coleta = Coleta.fromFirestore(doc);
              final statusLower = coleta.status.toLowerCase();

              final dataReferencia = coleta.dataCriacao ?? hoje;
              final isMesmoDia =
                  dataReferencia.year == hoje.year &&
                  dataReferencia.month == hoje.month &&
                  dataReferencia.day == hoje.day;

              final isEncerrado =
                  statusLower.contains('entregue') ||
                  statusLower.contains('concluído') ||
                  statusLower.contains('concluido');

              final isCancelado =
                  statusLower.contains('cancelado') ||
                  statusLower.contains('recusado');

              final isEmRota =
                  statusLower.contains('em rota') ||
                  statusLower.contains('em_rota') ||
                  statusLower.contains('coletado') ||
                  statusLower.contains('caminho');

              if (isEncerrado) {
                if (isMesmoDia) {
                  tempRecebidosHoje.add(coleta);
                } else {
                  tempHistorico.add(coleta);
                }
              } else if (isCancelado) {
                tempHistorico.add(coleta);
              } else if (isEmRota) {
                tempEmRota.add(coleta);
              } else {
                // 💡 Qualquer status como 'pendente', 'aguardando_coleta' ou 'indo_coletar' cai aqui
                tempAguardando.add(coleta);
              }
            }

            int sortKanban(Coleta a, Coleta b) {
              if (a.isEmergencia && !b.isEmergencia) return -1;
              if (!a.isEmergencia && b.isEmergencia) return 1;

              final dataA = a.dataCriacao ?? hoje;
              final dataB = b.dataCriacao ?? hoje;
              return dataB.compareTo(dataA);
            }

            tempAguardando.sort(sortKanban);
            tempEmRota.sort(sortKanban);
            tempRecebidosHoje.sort(sortKanban);
            tempHistorico.sort(sortKanban);

            aguardando = tempAguardando;
            emRota = tempEmRota;
            recebidosHoje = tempRecebidosHoje;
            historico = tempHistorico;
            isLoading = false;

            notifyListeners();
          },
          onError: (e) {
            debugPrint("Erro ao escutar exames do laboratório: $e");
            isLoading = false;
            notifyListeners();
          },
        );
  }

  // 💡 Lógica isolada na controladora para buscar motoboys vinculados ao Laboratório
  Future<void> _carregarMotoboysParceiros(String laboratorioId) async {
    try {
      final rotasSnapshot = await _db
          .collection('rotas_fixas')
          .where('laboratorioId', isEqualTo: laboratorioId)
          .where('ativa', isEqualTo: true)
          .get();

      final Map<String, String> motoboysUnicos = {};

      for (var doc in rotasSnapshot.docs) {
        final data = doc.data();
        final entregadorId = data['entregadorId']?.toString();
        final nomeEntregador = data['nomeEntregador']?.toString();

        if (entregadorId != null && nomeEntregador != null) {
          motoboysUnicos[entregadorId] = nomeEntregador;
        }
      }

      motoboysParceiros = motoboysUnicos.entries
          .map((e) => {'id': e.key, 'nome': e.value})
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao buscar rotas fixas para o laboratório: $e");
    }
  }

  Future<void> despacharColetaUrgencia({
    required String coletaId,
    required String tipoTransporte,
    required String nomeEntregador,
    String? entregadorId,
    String? veiculo,
    String? placa,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final isExterno = tipoTransporte == 'externo';
      final obs = isExterno
          ? 'Despacho Expresso via App. Motorista: $nomeEntregador. Veículo: $veiculo ($placa).'
          : 'Despachado para o motoboy parceiro: $nomeEntregador.';

      final updatePayload = {
        'status': 'indo_coletar', // 💡 Mudança para o novo status
        'nomeEntregador': nomeEntregador,
        'veiculoExterno': veiculo,
        'placaExterna': placa,
        'isTransporteExterno': isExterno,
        'historicoLogs': FieldValue.arrayUnion([
          {
            'status': 'indo_coletar', // 💡 Mudança para o novo status no log
            'data': Timestamp.now(),
            'observacao': obs,
            'usuario': 'Laboratório',
          },
        ]),
      };

      if (entregadorId != null && entregadorId.isNotEmpty) {
        updatePayload['entregadorId'] = entregadorId;
      }

      await _db
          .collection('chamados_coleta')
          .doc(coletaId)
          .update(updatePayload);
    } catch (e) {
      debugPrint("Erro ao despachar urgência: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
