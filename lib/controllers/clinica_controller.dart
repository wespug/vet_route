// lib/controllers/clinica_controller.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../repositories/coleta_repository.dart';

class ClinicaController {
  final ColetaRepository _repository;

  ClinicaController(this._repository);

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  // NOVOS ESTADOS REATIVOS
  final ValueNotifier<List<Marker>> motoboysProximos =
      ValueNotifier<List<Marker>>([]);
  final ValueNotifier<List<Coleta>> coletasEmTransito =
      ValueNotifier<List<Coleta>>([]);

  // Regra de Negócio: Carregar painel da clínica
  void carregarPainelLogistico(LatLng localClinica) {
    // 1. Simula motoboys rondando o bairro (Pins Laranjas)
    motoboysProximos.value = [
      Marker(
        markerId: const MarkerId('m1'),
        position: LatLng(
          localClinica.latitude + 0.002,
          localClinica.longitude + 0.002,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Motoboy Disponível'),
      ),
      Marker(
        markerId: const MarkerId('m2'),
        position: LatLng(
          localClinica.latitude - 0.003,
          localClinica.longitude + 0.001,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Motoboy Disponível'),
      ),
    ];

    // 2. Simula coletas que estão a caminho da clínica
    // (Num cenário real, buscaríamos isso do Repository)
  }

  Future<bool> solicitarMotoboy(
    Clinica minhaClinica,
    Laboratorio laboratorioDestino,
  ) async {
    try {
      isLoading.value = true;
      final novoId =
          '#${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

      final novaColeta = Coleta(
        id: novoId,
        clinicaOrigem: minhaClinica,
        laboratorioDestino: laboratorioDestino,
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

  void dispose() {
    isLoading.dispose();
    motoboysProximos.dispose();
    coletasEmTransito.dispose();
  }
}
