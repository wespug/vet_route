import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rota_model.dart';
import '../repositories/rota_repository.dart';

class RotaController {
  final RotaRepository _repository = RotaRepository();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<RotaModel>> rotas = ValueNotifier<List<RotaModel>>(
    [],
  );

  // Listas auxiliares para o formulário
  final ValueNotifier<List<Map<String, dynamic>>> entregadoresDisponiveis =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> clinicasDisponiveis =
      ValueNotifier([]);

  Future<void> inicializarDadosFormulario() async {
    try {
      // 💡 1. Busca Entregadores (Filtro EXATO da sua EntregadorController)
      final entregadoresSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('perfil', isEqualTo: 'entregadores')
          .get();

      List<Map<String, dynamic>> listaEntregadores = entregadoresSnap.docs.map((
        d,
      ) {
        final data = d.data();
        final nome =
            data['nome'] ??
            data['razaoSocial'] ??
            'Entregador (ID: ${d.id.substring(0, 4)})';
        return {'id': d.id, 'nome': nome};
      }).toList();

      // 🛡️ TRAVA DE SEGURANÇA SÊNIOR: Plano B caso a string exata falhe no Firebase
      if (listaEntregadores.isEmpty) {
        final fallbackSnap = await FirebaseFirestore.instance
            .collection('usuarios')
            .get();
        listaEntregadores = fallbackSnap.docs
            .where((d) {
              final data = d.data();
              final perfil = data['perfil']?.toString().toLowerCase() ?? '';
              final perfilId = data['perfilId']?.toString().toLowerCase() ?? '';
              return perfil.contains('entregador') ||
                  perfilId.contains('entregador');
            })
            .map((d) {
              final data = d.data();
              final nome =
                  data['nome'] ?? 'Entregador (ID: ${d.id.substring(0, 4)})';
              return {'id': d.id, 'nome': nome};
            })
            .toList();
      }

      entregadoresDisponiveis.value = listaEntregadores;

      // 💡 2. Busca Clínicas
      final clinicasSnap = await FirebaseFirestore.instance
          .collection('clinicas')
          .get();

      final listaClinicas = clinicasSnap.docs.map((d) {
        final data = d.data();
        final nome =
            data['nome'] ??
            data['nomeFantasia'] ??
            'Clínica (ID: ${d.id.substring(0, 4)})';
        return {'id': d.id, 'nome': nome};
      }).toList();

      clinicasDisponiveis.value = listaClinicas;
    } catch (e) {
      debugPrint("⚠️ ERRO CRÍTICO AO CARREGAR DADOS DO FORMULÁRIO: $e");
    }
  }

  Future<void> salvarRota(RotaModel rota) async {
    isLoading.value = true;
    try {
      if (rota.id == null || rota.id!.isEmpty) {
        await _repository.adicionarRota(rota);
      } else {
        await _repository.atualizarRota(rota.id!, rota);
      }
      await carregarRotas(rota.laboratorioId);
    } catch (e) {
      debugPrint("Erro ao salvar rota: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> carregarRotas(String laboratorioId) async {
    if (laboratorioId.isEmpty) return;
    isLoading.value = true;
    try {
      rotas.value = await _repository.buscarRotasPorLaboratorio(laboratorioId);
    } catch (e) {
      debugPrint("Erro ao carregar rotas: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removerRota(String rotaId, String laboratorioId) async {
    isLoading.value = true;
    try {
      await _repository.deletarRota(rotaId);
      await carregarRotas(laboratorioId);
    } catch (e) {
      debugPrint("Erro ao deletar rota: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    rotas.dispose();
    entregadoresDisponiveis.dispose();
    clinicasDisponiveis.dispose();
  }
}
