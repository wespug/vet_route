// lib/controllers/coleta_controller.dart

import 'package:flutter/material.dart';
import '../models/coleta_model.dart';
import '../repositories/coleta_repository.dart';

class ColetaController {
  // Injeção de Dependência: A controladora exige um repositório para funcionar
  final ColetaRepository _repository;

  ColetaController(this._repository);

  // Notificadores reativos para a View escutar
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<Coleta>> coletasNoRadar =
      ValueNotifier<List<Coleta>>([]);

  // Regra de Negócio: Buscar as coletas
  Future<void> carregarColetas() async {
    try {
      isLoading.value = true; // Avisa a tela para mostrar o "Loading"

      final lista = await _repository.buscarColetasNoRadar();
      coletasNoRadar.value =
          lista; // Atualiza a lista com os dados do repositório
    } catch (e) {
      // Aqui trataríamos erros (Ex: Logar no Sentry/Crashlytics ou mostrar alerta)
      debugPrint('Erro ao carregar coletas: $e');
    } finally {
      isLoading.value =
          false; // Desliga o "Loading" independente de sucesso ou erro
    }
  }

  // Boa prática sênior: Limpar os notificadores da memória quando não forem mais usados
  void dispose() {
    isLoading.dispose();
    coletasNoRadar.dispose();
  }
}
