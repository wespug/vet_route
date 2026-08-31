import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/coleta_model.dart';
import '../repositories/coleta_repository.dart';

class ColetaController extends ChangeNotifier {
  final ColetaRepository _repository;

  ColetaController(this._repository);

  // Notificadores reativos para a View escutar
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<Coleta>> coletasNoRadar =
      ValueNotifier<List<Coleta>>([]);

  // Getters de atalho/compatibilidade para as Views
  bool get carregando => isLoading.value;
  List<Coleta> get coletas => coletasNoRadar.value;

  // Inscrição para escutar atualizações em tempo real do Firestore
  StreamSubscription<List<Coleta>>? _coletasSubscription;

  // ===========================================================================
  // 1. GETTERS DE REGRAS DE NEGÓCIO E FILTRAGEM (MVC)
  // ===========================================================================

  /// Determina se um item é finalizado, concluído, cancelado ou recusado
  bool isItemFinalizadoOuRecusado(Coleta item) {
    final st = item.status.trim().toLowerCase();

    // IMPORTANTE: "Recusado" aqui é a recusa final pelo laboratório.
    // Se o motoboy recusa, o status volta para "aguardando_entregador" e não cai nesta malha.
    return st.contains('recusad') ||
        st.contains('recusar') ||
        st.contains('cancel') ||
        st.contains('conclu') ||
        st.contains('entregue') ||
        st.contains('finalizad');
  }

  /// Retorna apenas as coletas e pedidos em aberto/ativos
  List<Coleta> get coletasAtivas =>
      coletas.where((c) => !isItemFinalizadoOuRecusado(c)).toList();

  /// Retorna apenas as coletas e pedidos finalizados ou recusados
  List<Coleta> get coletasFinalizadas =>
      coletas.where((c) => isItemFinalizadoOuRecusado(c)).toList();

  /// Agrupa e ordena itens por data (dos mais antigos para os mais recentes)
  Map<String, List<Coleta>> agruparEOrdenarColetas(List<Coleta> lista) {
    final Map<String, List<Coleta>> agrupados = {};
    final formatadorChave = DateFormat('yyyy-MM-dd');

    for (var item in lista) {
      final data = item.dataCriacao ?? DateTime.now();
      final chaveData = formatadorChave.format(data);

      if (!agrupados.containsKey(chaveData)) {
        agrupados[chaveData] = [];
      }
      agrupados[chaveData]!.add(item);
    }

    final chavesOrdenadas = agrupados.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final Map<String, List<Coleta>> resultadoOrdenado = {};
    for (var chave in chavesOrdenadas) {
      final listaDia = agrupados[chave]!;
      listaDia.sort((a, b) {
        final dataA = a.dataCriacao ?? DateTime.now();
        final dataB = b.dataCriacao ?? DateTime.now();
        return dataA.compareTo(dataB);
      });
      resultadoOrdenado[chave] = listaDia;
    }

    return resultadoOrdenado;
  }

  // ===========================================================================
  // 2. MÉTODOS DE APRESENTAÇÃO (Injetados para manter a View limpa)
  // ===========================================================================

  /// Formata a data para os cabeçalhos da lista de entregas do Motoboy
  String formatarDataCabecalho(String dataStr) {
    try {
      final data = DateTime.parse(dataStr);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));

      if (DateFormat('yyyy-MM-dd').format(hoje) == dataStr) {
        return 'Hoje, ${DateFormat("dd 'de' MMMM", 'pt_BR').format(data)}';
      } else if (DateFormat('yyyy-MM-dd').format(ontem) == dataStr) {
        return 'Ontem, ${DateFormat("dd 'de' MMMM", 'pt_BR').format(data)}';
      }

      return DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(data);
    } catch (_) {
      return dataStr;
    }
  }

  /// Retorna o texto pluralizado corretamente para a View
  String obterTextoQuantidade(int qtd) {
    return "$qtd ${qtd == 1 ? 'PARADA' : 'PARADAS'}";
  }

  // ===========================================================================
  // 3. MÉTODOS DE STREAM E REPOSITÓRIO
  // ===========================================================================

  /// Escuta as coletas ativas no radar em tempo real (Visão Geral)
  void escutarColetasNoRadar() {
    isLoading.value = true;
    coletasNoRadar.value =
        []; // 💡 LIMPANDO O CACHE: Evita o vazamento visual de dados anteriores!
    notifyListeners();
    _coletasSubscription?.cancel();

    _coletasSubscription = _repository.streamColetasNoRadar().listen(
      (lista) {
        coletasNoRadar.value = lista;
        isLoading.value = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Erro ao escutar coletas no radar: $e');
        isLoading.value = false;
        notifyListeners();
      },
    );
  }

  /// Alias para escutarColetasNoRadar (usado pela DirecionamentoColetasView)
  void escutarTodasColetasAtivas() {
    escutarColetasNoRadar();
  }

  /// Escuta as coletas direcionadas a um entregador específico
  void escutarColetasDoEntregador(String entregadorId) {
    isLoading.value = true;
    coletasNoRadar.value =
        []; // 💡 LIMPANDO O CACHE: Garante que um motoboy novato abra a tela VAZIA.
    notifyListeners();
    _coletasSubscription?.cancel();

    _coletasSubscription = _repository
        .streamColetasPorEntregador(entregadorId)
        .listen(
          (lista) {
            coletasNoRadar.value = lista;
            isLoading.value = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erro ao escutar coletas do entregador: $e');
            isLoading.value = false;
            notifyListeners();
          },
        );
  }

  /// Ação do Motoboy ao recusar uma coleta designada a ele
  Future<void> recusarColeta(String coletaId) async {
    try {
      isLoading.value = true;
      notifyListeners();

      // 💡 Regra de Negócio: O status volta para "Aguardando Entregador".
      await _repository.atualizarStatusColeta(
        coletaId,
        'aguardando_entregador',
      );

      // ALERTA DE REPOSITÓRIO:
      // Se houver um método no seu _repository para desvincular o entregador
      // (zerando o campo entregadorId e nomeEntregador), é essencial chamá-lo aqui
      // para garantir que essa corrida não apareça mais para ELE.
    } catch (e) {
      debugPrint('Erro ao recusar coleta ($coletaId): $e');
      rethrow;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  /// Busca pontual legada
  Future<void> carregarColetas() async {
    try {
      isLoading.value = true;
      coletasNoRadar.value = []; // Limpeza de cache no carregamento também
      notifyListeners();

      final lista = await _repository.buscarColetasNoRadar();
      coletasNoRadar.value = lista;
    } catch (e) {
      debugPrint('Erro ao carregar coletas: $e');
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _coletasSubscription?.cancel();
    isLoading.dispose();
    coletasNoRadar.dispose();
    super.dispose();
  }
}
