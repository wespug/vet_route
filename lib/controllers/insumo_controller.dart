import 'package:flutter/material.dart';
import '../models/insumo_model.dart';
import '../repositories/insumo_repository.dart';

class InsumoController {
  final InsumoRepository _repository = InsumoRepository();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<InsumoModel>> insumos =
      ValueNotifier<List<InsumoModel>>([]);

  Future<void> salvarInsumo({
    required String laboratorioId,
    required String descricao,
    required String tipo,
    required String tamanho,
    required String volume,
  }) async {
    if (laboratorioId.isEmpty) return;

    isLoading.value = true;

    try {
      final novoInsumo = InsumoModel(
        laboratorioId: laboratorioId,
        descricao: descricao,
        tipo: tipo,
        tamanho: tamanho,
        volume: volume,
      );

      await _repository.adicionarInsumo(novoInsumo);
      await carregarInsumos(laboratorioId);
    } catch (e) {
      debugPrint("Erro ao salvar insumo: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> carregarInsumos(String laboratorioId) async {
    if (laboratorioId.isEmpty) return;

    isLoading.value = true;
    try {
      insumos.value = await _repository.buscarInsumosPorLaboratorio(
        laboratorioId,
      );
    } catch (e) {
      debugPrint("Erro ao carregar insumos: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removerInsumo(String insumoId, String laboratorioId) async {
    isLoading.value = true;
    try {
      await _repository.deletarInsumo(insumoId);
      await carregarInsumos(laboratorioId);
    } catch (e) {
      debugPrint("Erro ao deletar insumo: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    insumos.dispose();
  }
}
