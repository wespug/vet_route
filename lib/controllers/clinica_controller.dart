import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 💡 Necessário para consulta direta
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/perfil_usuario.dart'; // 💡 Necessário para o Enum
import '../repositories/coleta_repository.dart';

class ClinicaController {
  final ColetaRepository _repository;
  final FirebaseFirestore _db =
      FirebaseFirestore.instance; // 💡 Instância do Firestore

  ClinicaController(this._repository);

  // --- ESTADOS REATIVOS (USO DO CLIENTE) ---
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<Clinica?> clinicaAtual = ValueNotifier<Clinica?>(null);
  final ValueNotifier<Laboratorio?> labDestino = ValueNotifier<Laboratorio?>(
    null,
  );

  final ValueNotifier<List<Marker>> motoboysProximos =
      ValueNotifier<List<Marker>>([]);
  final ValueNotifier<List<Coleta>> coletasEmTransito =
      ValueNotifier<List<Coleta>>([]);

  // --- ESTADOS REATIVOS (USO DO ADMIN) ---
  final ValueNotifier<List<Clinica>> todasClinicas =
      ValueNotifier<List<Clinica>>([]); // 💡 Adicionado para armazenar a lista

  /// Inicializa o painel carregando os dados do repositório real
  Future<void> inicializarPainel() async {
    isLoading.value = true;
    try {
      clinicaAtual.value = await _repository.obterClinicaLogada();
      labDestino.value = await _repository.obterLaboratorioPadrao();

      // Atualizado para usar o getter 'coordenada' de forma segura ou as propriedades diretas
      if (clinicaAtual.value != null &&
          clinicaAtual.value!.endereco.coordenada != null) {
        _carregarMotoboysProximos(clinicaAtual.value!.endereco.coordenada!);
      }
    } catch (e) {
      debugPrint('Erro ao inicializar painel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _carregarMotoboysProximos(LatLng local) {
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

  // 💡 O MÉTODO INJETADO: Agora atualiza a variável 'todasClinicas'
  void ouvirClinicas() {
    _db
        .collection('usuarios')
        .where(
          'perfil',
          isEqualTo: PerfilUsuario.clinica.firebaseValue,
        ) // 💡 Consertado para firebaseValue
        .snapshots()
        .listen((snapshot) {
          todasClinicas.value = snapshot.docs
              .map((doc) => Clinica.fromFirestore(doc))
              .toList();
        });
  }

  void dispose() {
    isLoading.dispose();
    clinicaAtual.dispose();
    labDestino.dispose();
    motoboysProximos.dispose();
    coletasEmTransito.dispose();
    todasClinicas.dispose(); // 💡 Descarte correto de memória
  }
}
