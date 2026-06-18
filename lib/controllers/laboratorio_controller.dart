import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/laboratorio_model.dart';
import '../repositories/coleta_repository.dart';

/// Enum para controlar as abas do painel do laboratório
enum TabLabDashboard { emEspera, aCaminho, recebidas }

class LaboratorioController {
  final ColetaRepository _repository;

  // === ESTADO REATIVO ===
  final ValueNotifier<Laboratorio?> laboratorioAtual = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<TabLabDashboard> tabAtiva = ValueNotifier(
    TabLabDashboard.emEspera,
  );

  /// Lista temporária que futuramente virá do rastreio em tempo real
  final ValueNotifier<List<Marker>> motoboysACaminho = ValueNotifier([]);

  /// 💡 Os marcadores consolidados que a View vai apenas desenhar de forma passiva
  final ValueNotifier<Set<Marker>> marcadoresMapa = ValueNotifier({});

  LaboratorioController(this._repository);

  /// Método inicial invocado pelo initState da View
  Future<void> inicializarPainel() async {
    isLoading.value = true;
    try {
      // 1. Busca os dados reais no FirestoreColetaRepository
      final lab = await _repository.obterLaboratorioPadrao();
      laboratorioAtual.value = lab;

      // 2. Monta os pinos iniciais no mapa com base nos dados do laboratório
      _atualizarMarcadores();
    } catch (e) {
      debugPrint("❌ Erro ao inicializar painel do Laboratório: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Alterna entre as abas do dashboard e atualiza o mapa de acordo
  void alterarTab(TabLabDashboard novaTab) {
    tabAtiva.value = novaTab;
    _atualizarMarcadores();
  }

  /// 💡 O método em falta! Trata a intenção de receber a encomenda
  void receberEncomenda() {
    // 📸 Futuramente: Aqui faremos a chamada para abrir a câmara com o scanner de QR Code
    // e atualizaremos o estado da recolha para 'Recebido' direto no Firestore.
    debugPrint(
      "📸 [Controller] Fluxo de leitura de QR Code disparado com sucesso.",
    );
  }

  /// Lógica interna para consolidar os marcadores do mapa (Abstração total da View)
  void _atualizarMarcadores() {
    final lab = laboratorioAtual.value;
    if (lab == null) return;

    final Set<Marker> novosMarcadores = {};

    // 1. Sempre insere o pino do próprio laboratório no mapa
    novosMarcadores.add(
      Marker(
        markerId: const MarkerId('meu_lab'),
        position: lab.endereco.coordenada!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: lab.nome),
      ),
    );

    // 2. Se a aba selecionada for "A Caminho", injeta os motoboys ativos no radar
    if (tabAtiva.value == TabLabDashboard.aCaminho) {
      novosMarcadores.addAll(motoboysACaminho.value);
    }

    // 3. Atualiza o ValueNotifier para notificar a View
    marcadoresMapa.value = novosMarcadores;
  }

  /// Libera a gestão de memória ao fechar o ecrã
  void dispose() {
    laboratorioAtual.dispose();
    isLoading.dispose();
    tabAtiva.dispose();
    motoboysACaminho.dispose();
    marcadoresMapa.dispose();
  }
}
