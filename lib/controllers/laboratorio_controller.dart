// lib/controllers/laboratorio_controller.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/coleta_model.dart';
import '../repositories/coleta_repository.dart';

// Estados do Dashboard do Laboratório
enum TabLabDashboard { emEspera, aCaminho, recebidas }

class LaboratorioController {
  final ColetaRepository _repository;

  LaboratorioController(this._repository);

  // Controle da aba ativa no Dashboard
  final ValueNotifier<TabLabDashboard> tabAtiva =
      ValueNotifier<TabLabDashboard>(TabLabDashboard.aCaminho);

  // Listas reativas para as três colunas
  final ValueNotifier<List<Coleta>> coletasEmEspera =
      ValueNotifier<List<Coleta>>([]);
  final ValueNotifier<List<Coleta>> coletasACaminho =
      ValueNotifier<List<Coleta>>([]);
  final ValueNotifier<List<Coleta>> coletasRecebidas =
      ValueNotifier<List<Coleta>>([]);

  // Mock de marcadores de motoboys se aproximando
  final ValueNotifier<List<Marker>> motoboysACaminho =
      ValueNotifier<List<Marker>>([]);

  void carregarDashboard(LatLng localLaboratorio) {
    // Aqui no futuro chamaremos _repository.buscarColetasPorLaboratorio()

    // 1. Simulação: Motoboys que estão com a coleta e vindo para o Lab
    motoboysACaminho.value = [
      Marker(
        markerId: const MarkerId('moto_1'),
        position: LatLng(
          localLaboratorio.latitude + 0.005,
          localLaboratorio.longitude + 0.005,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Motoboy Carlos - Coleta #001'),
      ),
      Marker(
        markerId: const MarkerId('moto_2'),
        position: LatLng(
          localLaboratorio.latitude - 0.003,
          localLaboratorio.longitude - 0.002,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Motoboy Ana - Coleta #005'),
      ),
    ];

    // Simulando que existem 3 coletas aguardando motoboy nas clínicas
    coletasEmEspera.value = [
      // ... mocks
    ];
  }

  void alterarTab(TabLabDashboard novaTab) {
    tabAtiva.value = novaTab;
  }

  void dispose() {
    tabAtiva.dispose();
    coletasEmEspera.dispose();
    coletasACaminho.dispose();
    coletasRecebidas.dispose();
    motoboysACaminho.dispose();
  }
}
