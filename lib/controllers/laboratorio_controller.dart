import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';

import '../models/coleta_model.dart';
import '../repositories/coleta_repository.dart';

// Estados do Dashboard do Laboratório
enum TabLabDashboard { emEspera, aCaminho, recebidas }

class LaboratorioController with LoggerMixin {
  // 1. Corrigido: Agora referenciamos o Repository correto
  // ignore: unused_field
  final ColetaRepository _coletaRepository;

  // 2. Construtor corrigido: Injetando apenas o que é necessário
  LaboratorioController(this._coletaRepository);

  void testarLog() {
    log.i('Testando o log vindo do mixin!');
  }

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

  Future<void> carregarDashboard(LatLng localLaboratorio) async {
    // Exemplo de uso do repository e do log (limpa o erro de variável não usada)
    log.i('Carregando dados do laboratório...');

    // final dados = await _coletaRepository.buscarColetas();
    // log.i('Dados carregados: ${dados.length}');

    // Simulação: Motoboys que estão com a coleta e vindo para o Lab
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
  }

  void alterarTab(TabLabDashboard novaTab) {
    tabAtiva.value = novaTab;
  }

  // Dispose para limpar a memória
  void dispose() {
    tabAtiva.dispose();
    coletasEmEspera.dispose();
    coletasACaminho.dispose();
    coletasRecebidas.dispose();
    motoboysACaminho.dispose();
  }
}
