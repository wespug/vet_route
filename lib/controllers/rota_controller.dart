import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rota_model.dart';
import '../repositories/rota_repository.dart';

/// Classe auxiliar para comunicação limpa de status entre Controller e View
class ResultadoOperacao {
  final bool sucesso;
  final String mensagem;

  ResultadoOperacao({required this.sucesso, required this.mensagem});
}

class RotaController {
  final RotaRepository _repository = RotaRepository();

  // Estados reativos para a UI
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<List<RotaModel>> rotas = ValueNotifier<List<RotaModel>>(
    [],
  );

  // Listas auxiliares para os Dropdowns do formulário
  final ValueNotifier<List<Map<String, dynamic>>> entregadoresDisponiveis =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> clinicasDisponiveis =
      ValueNotifier([]);

  // --- 1. BUSCA E CARREGAMENTO DE DADOS ---

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

  Future<void> inicializarDadosFormulario() async {
    try {
      // 💡 1. Busca Entregadores
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

      // Fallback de segurança para entregadores
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

  // --- 2. REGRAS DE NEGÓCIO DO MODAL (VALIDAÇÕES DE PARADAS) ---

  ResultadoOperacao adicionarParadaTemporaria({
    required String? entregadorId,
    required String? clinicaId,
    required String nomeClinica,
    required String turno,
    required List<String> diasSelecionados,
    required List<ParadaRota> paradasAtuais,
  }) {
    if (entregadorId == null || entregadorId.isEmpty) {
      return ResultadoOperacao(
        sucesso: false,
        mensagem: "Selecione o Motoboy primeiro!",
      );
    }
    if (clinicaId == null || clinicaId.isEmpty) {
      return ResultadoOperacao(
        sucesso: false,
        mensagem: "Selecione a Clínica para a parada!",
      );
    }
    if (diasSelecionados.isEmpty) {
      return ResultadoOperacao(
        sucesso: false,
        mensagem: "Selecione ao menos um dia da semana!",
      );
    }

    // Regra de formatação do texto exibido no trajeto
    final String formatoHorario =
        "Turno: $turno (${diasSelecionados.join(', ')})";

    paradasAtuais.add(
      ParadaRota(
        clinicaId: clinicaId,
        nomeClinica: nomeClinica,
        horarioPrevisto: formatoHorario,
      ),
    );

    return ResultadoOperacao(sucesso: true, mensagem: "Parada adicionada!");
  }

  // --- 3. OPERAÇÕES DE PERSISTÊNCIA ---

  Future<bool> salvarRota(RotaModel rota) async {
    isLoading.value = true;
    try {
      if (rota.id == null || rota.id!.isEmpty) {
        await _repository.adicionarRota(rota);
      } else {
        await _repository.atualizarRota(rota.id!, rota);
      }
      await carregarRotas(rota.laboratorioId);
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar rota: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletarRota(String rotaId, String laboratorioId) async {
    isLoading.value = true;
    try {
      await _repository.deletarRota(rotaId);
      await carregarRotas(laboratorioId);
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar rota: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- 4. GERENCIAMENTO DE MEMÓRIA ---

  void dispose() {
    isLoading.dispose();
    rotas.dispose();
    entregadoresDisponiveis.dispose();
    clinicasDisponiveis.dispose();
  }
}
