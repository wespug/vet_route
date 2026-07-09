import 'package:flutter/material.dart';
import '../models/exame_model.dart';
import '../repositories/exame_repository.dart';

class ExameController {
  final ExameRepository _repository = ExameRepository();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<ExameModel>> exames =
      ValueNotifier<List<ExameModel>>([]);

  Future<void> salvarExame({
    required String laboratorioId,
    required String nome,
    required String detalhes,
    required String porte,
    required String especie,
  }) async {
    if (laboratorioId.isEmpty) return;

    isLoading.value = true;

    try {
      final novoExame = ExameModel(
        laboratorioId:
            laboratorioId, // Recebe do parâmetro agora, não do usuário logado!
        nome: nome,
        detalhes: detalhes,
        porte: porte,
        especie: especie,
      );

      await _repository.adicionarExame(novoExame);
      await carregarExames(laboratorioId); // Atualiza a lista após salvar
    } catch (e) {
      debugPrint("Erro ao salvar exame: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> carregarExames(String laboratorioId) async {
    if (laboratorioId.isEmpty) return;

    isLoading.value = true;
    try {
      exames.value = await _repository.buscarExamesPorLaboratorio(
        laboratorioId,
      );
    } catch (e) {
      debugPrint("Erro ao carregar exames: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removerExame(String exameId, String laboratorioId) async {
    isLoading.value = true;
    try {
      await _repository.deletarExame(exameId);
      await carregarExames(laboratorioId);
    } catch (e) {
      debugPrint("Erro ao deletar exame: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    exames.dispose();
  }
}
