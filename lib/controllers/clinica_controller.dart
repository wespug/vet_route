import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../repositories/coleta_repository.dart';

class ClinicaController extends ChangeNotifier {
  final ColetaRepository _repository;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _chamadosSubscription;

  ClinicaController(this._repository);

  // --- 📊 ESTADOS REATIVOS UNIFICADOS (ValueNotifiers Originais) ---
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<Clinica?> clinicaAtual = ValueNotifier<Clinica?>(null);
  final ValueNotifier<Laboratorio?> labDestino = ValueNotifier<Laboratorio?>(
    null,
  );
  final ValueNotifier<List<Marker>> motoboysProximos =
      ValueNotifier<List<Marker>>([]);
  final ValueNotifier<List<Coleta>> coletasEmTransito =
      ValueNotifier<List<Coleta>>([]);

  // --- 📊 ESTADOS REATIVOS PARA O ADMIN WEB ---
  final ValueNotifier<List<Clinica>> todasClinicas =
      ValueNotifier<List<Clinica>>([]);

  // --- 💎 NOVOS FLUXOS UNIFICADOS DO DASHBOARD REALTIME ---
  List<Map<String, dynamic>> chamadosAtivos = [];
  List<Map<String, dynamic>> chamadosHistorico = [];

  int qtdEmRota = 0;
  int qtdAguardando = 0;
  int qtdConcluidos = 0;
  bool carregandoDashboard = true;

  // =========================================================================
  // 🟢 ESCUTA EM TEMPO REAL (MÉTODO CENTRALIZADO NOVO)
  // =========================================================================
  void inicializarDashboardRealtime() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      carregandoDashboard = false;
      notifyListeners();
      return;
    }

    carregandoDashboard = true;
    notifyListeners();

    _chamadosSubscription?.cancel();
    _chamadosSubscription = _db
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) {
            chamadosAtivos.clear();
            chamadosHistorico.clear();
            qtdEmRota = 0;
            qtdAguardando = 0;
            qtdConcluidos = 0;

            final docs = snapshot.docs.toList();

            docs.sort((a, b) {
              final tA = a.data()['dataCriacao'] as Timestamp?;
              final tB = b.data()['dataCriacao'] as Timestamp?;
              if (tA != null && tB != null) return tB.compareTo(tA);
              return 0;
            });

            for (var doc in docs) {
              final data = doc.data();
              data['id'] = doc.id;
              final status = data['status'] ?? 'Aguardando';

              if (status == 'Aguardando' || status == 'Aguardando Entregador') {
                qtdAguardando++;
                chamadosAtivos.add(data);
              } else if (status == 'Em Rota' ||
                  status == 'A Caminho' ||
                  status == 'Coletado') {
                qtdEmRota++;
                chamadosAtivos.add(data);
              } else {
                qtdConcluidos++;
                chamadosHistorico.add(data);
              }
            }

            carregandoDashboard = false;
            notifyListeners();
          },
          onError: (err) {
            debugPrint("Erro Firestore Realtime na ClinicaController: $err");
            carregandoDashboard = false;
            notifyListeners();
          },
        );
  }

  // =========================================================================
  // 🟢 MÉTODOS DE ADMINISTRAÇÃO WEB
  // =========================================================================
  Future<void> carregarClinicas() async {
    isLoading.value = true;
    try {
      final snapshot = await _db.collection('clinicas').get();
      final List<Clinica> lista = snapshot.docs.map((doc) {
        return Clinica.fromFirestore(doc);
      }).toList();
      todasClinicas.value = lista;
    } catch (e) {
      debugPrint('Erro ao carregar clinicas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 🛠️ CORREÇÃO: Sem copyWith. Usando direto o .toMap() suportado pela model.
  Future<bool> salvarClinica(Clinica clinica) async {
    isLoading.value = true;
    try {
      final docRef = _db.collection('clinicas').doc();
      await docRef.set(clinica.toMap());
      await carregarClinicas();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar clinica: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🛠️ CORREÇÃO: Recebendo (String id, Clinica clinica) como a View envia.
  Future<bool> atualizarClinica(String id, Clinica clinica) async {
    if (id.isEmpty) return false;
    isLoading.value = true;
    try {
      await _db.collection('clinicas').doc(id).update(clinica.toMap());
      await carregarClinicas();
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar clinica: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletarClinica(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('clinicas').doc(id).delete();
      await carregarClinicas();
    } catch (e) {
      debugPrint('Erro ao deletar clinica: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // 🟢 OPERAÇÕES LOGÍSTICAS DA CLÍNICA
  // =========================================================================
  void carregarMotoboysProximos(LatLng local) {
    motoboysProximos.value = [
      Marker(
        markerId: const MarkerId('m1'),
        position: LatLng(local.latitude + 0.002, local.longitude + 0.002),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('m2'),
        position: LatLng(local.latitude - 0.003, local.longitude + 0.001),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    ];
  }

  Future<bool> solicitarMotoboy() async {
    final clinica = clinicaAtual.value;
    final lab = labDestino.value;

    if (clinica == null || lab == null) return false;

    try {
      isLoading.value = true;
      final novaColeta = Coleta(
        id: '#${DateTime.now().millisecondsSinceEpoch}',
        clinicaOrigem: clinica,
        laboratorioDestino: lab,
        status: 'Aguardando',
      );

      await _repository.solicitarColeta(novaColeta);
      return true;
    } catch (e) {
      debugPrint('Erro ao solicitar: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _chamadosSubscription?.cancel();
    isLoading.dispose();
    clinicaAtual.dispose();
    labDestino.dispose();
    motoboysProximos.dispose();
    coletasEmTransito.dispose();
    todasClinicas.dispose();
    super.dispose();
  }
}
