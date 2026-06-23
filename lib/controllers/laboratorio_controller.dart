import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/laboratorio_model.dart';
import '../repositories/firestore_coleta_repository.dart'; // 💡 Importação do repositório real!

/// Enum para controlar as abas do painel do laboratório
enum TabLabDashboard { emEspera, aCaminho, recebidas }

class LaboratorioController {
  final FirestoreColetaRepository
  _repository; // 💡 Agora ele aceita o FirestoreColetaRepository!

  // === ESTADO REATIVO ===
  final ValueNotifier<Laboratorio?> laboratorioAtual = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<TabLabDashboard> tabAtiva = ValueNotifier(
    TabLabDashboard.emEspera,
  );

  final ValueNotifier<List<Marker>> motoboysACaminho = ValueNotifier([]);
  final ValueNotifier<Set<Marker>> marcadoresMapa = ValueNotifier({});

  // 💡 O Construtor que a tela estava pedindo:
  LaboratorioController(this._repository);

  Future<void> inicializarPainel() async {
    isLoading.value = true;
    try {
      final lab = await _repository.obterLaboratorioPadrao();
      laboratorioAtual.value = lab;
      _atualizarMarcadores();
    } catch (e) {
      debugPrint("❌ Erro ao inicializar painel do Laboratório: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void alterarTab(TabLabDashboard novaTab) {
    tabAtiva.value = novaTab;
    _atualizarMarcadores();
  }

  // 💡 O método que estava vermelho na sua tela:
  void receberEncomenda() {
    debugPrint(
      "📸 [Controller] Fluxo de leitura de QR Code disparado com sucesso.",
    );
  }

  void _atualizarMarcadores() {
    final lab = laboratorioAtual.value;
    if (lab == null) return;

    final Set<Marker> novosMarcadores = {};

    if (lab.endereco.coordenada != null) {
      novosMarcadores.add(
        Marker(
          markerId: const MarkerId('meu_lab'),
          position: lab.endereco.coordenada!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: lab.nome),
        ),
      );
    }

    if (tabAtiva.value == TabLabDashboard.aCaminho) {
      novosMarcadores.addAll(motoboysACaminho.value);
    }

    marcadoresMapa.value = novosMarcadores;
  }

  void dispose() {
    laboratorioAtual.dispose();
    isLoading.dispose();
    tabAtiva.dispose();
    motoboysACaminho.dispose();
    marcadoresMapa.dispose();
  }
}
