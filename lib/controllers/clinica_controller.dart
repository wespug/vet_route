// lib/controllers/clinica_controller.dart

import 'package:flutter/material.dart';
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../repositories/coleta_repository.dart';

class ClinicaController {
  final ColetaRepository _repository;

  ClinicaController(this._repository);

  // Controle de estado para a tela (mostrar loading)
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  // Regra de Negócio: Criar e enviar a solicitação
  Future<bool> solicitarMotoboy(
    Clinica minhaClinica,
    Laboratorio laboratorioDestino,
  ) async {
    try {
      isLoading.value = true;

      // Geramos um ID aleatório para a nova coleta simulando o backend
      final novoId =
          '#${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

      final novaColeta = Coleta(
        id: novoId,
        clinicaOrigem: minhaClinica,
        laboratorioDestino: laboratorioDestino,
        status: 'Aguardando', // Status inicial obrigatório
      );

      // Salva no repositório
      await _repository.solicitarColeta(novaColeta);

      return true; // Sucesso
    } catch (e) {
      debugPrint('Erro ao solicitar coleta: $e');
      return false; // Falha
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
  }
}
