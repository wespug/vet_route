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
  bool isLoading = true;

  void iniciarEscuta(String laboratorioId) {
    isLoading = true;
    notifyListeners();

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

              // Base de tempo para saber se chegou "hoje"
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
                tempAguardando.add(coleta);
              }
            }

            // Ordena do mais recente para o mais antigo
            int sortByDate(Coleta a, Coleta b) =>
                (b.dataCriacao ?? hoje).compareTo(a.dataCriacao ?? hoje);

            tempAguardando.sort(sortByDate);
            tempEmRota.sort(sortByDate);
            tempRecebidosHoje.sort(sortByDate);
            tempHistorico.sort(sortByDate);

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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
