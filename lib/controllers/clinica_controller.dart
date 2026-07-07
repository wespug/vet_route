import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/endereco_model.dart';
import '../repositories/coleta_repository.dart';

class ClinicaController {
  final ColetaRepository _repository;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ClinicaController(this._repository);

  // --- ESTADOS REATIVOS (USO DO CLIENTE) ---
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<Clinica?> clinicaAtual = ValueNotifier<Clinica?>(null);
  final ValueNotifier<Laboratorio?> labDestino = ValueNotifier<Laboratorio?>(
    null,
  );
  final ValueNotifier<List<Marker>> motoboysProximos =
      ValueNotifier<List<Marker>>([]);
  final ValueNotifier<List<Coleta>> coletasEmTransito =
      ValueNotifier<List<Coleta>>([]);

  // --- ESTADOS REATIVOS (USO DO ADMIN) ---
  final ValueNotifier<List<Clinica>> todasClinicas =
      ValueNotifier<List<Clinica>>([]);

  // =========================================================================
  // 🟢 MÉTODOS DE ADMINISTRAÇÃO WEB (CRUD NO FIRESTORE)
  // =========================================================================

  Future<void> carregarClinicas() async {
    isLoading.value = true;
    try {
      final snapshot = await _db.collection('clinicas').get();
      todasClinicas.value = snapshot.docs.map<Clinica>((doc) {
        final data = doc.data();
        return Clinica(
          id: doc.id,
          nome: data['nome'] ?? 'Sem nome',
          email: data['email'] ?? 'Sem e-mail',
          telefone: data['telefone'] ?? 'Sem telefone',
          cnpj: data['cnpj'] ?? '00.000.000/0000-00',
          // 💡 ALINHADO PERFEITAMENTE: Mapeamento usando o construtor real de Endereco
          endereco: Endereco(
            cep: data['cep'] ?? '',
            logradouro: data['logradouro'] ?? 'A definir',
            numero: data['numero'] ?? '',
            complemento: data['complemento'] ?? '',
            bairro: data['bairro'] ?? '',
            cidade: data['cidade'] ?? '',
            estado: data['estado'] ?? '',
            latitude: data['latitude'] != null
                ? (data['latitude'] as num).toDouble()
                : null,
            longitude: data['longitude'] != null
                ? (data['longitude'] as num).toDouble()
                : null,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao carregar clínicas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> adicionarClinica(String nome, String email) async {
    isLoading.value = true;
    try {
      await _db.collection('clinicas').add({
        'nome': nome,
        'email': email,
        'telefone': '',
        'cnpj': '',
        'cep': '',
        'logradouro': '',
        'numero': '',
        'complemento': '',
        'bairro': '',
        'cidade': '',
        'estado': '',
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      await carregarClinicas();
    } catch (e) {
      debugPrint('Erro ao adicionar clínica: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editarClinica(String id, String nome, String email) async {
    isLoading.value = true;
    try {
      await _db.collection('clinicas').doc(id).update({
        'nome': nome,
        'email': email,
      });
      await carregarClinicas();
    } catch (e) {
      debugPrint('Erro ao editar clínica: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> excluirClinica(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('clinicas').doc(id).delete();
      await carregarClinicas();
    } catch (e) {
      debugPrint('Erro ao excluir clínica: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // 🔵 MÉTODOS ORIGINAIS DE USO DO CLIENTE
  // =========================================================================

  Future<void> inicializarPainel() async {
    isLoading.value = true;
    try {
      clinicaAtual.value = await _repository.obterClinicaLogada();
      labDestino.value = await _repository.obterLaboratorioPadrao();

      if (clinicaAtual.value != null &&
          clinicaAtual.value!.endereco.coordenada != null) {
        _carregarMotoboysProximos(clinicaAtual.value!.endereco.coordenada!);
      }
    } catch (e) {
      debugPrint('Erro ao inicializar painel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _carregarMotoboysProximos(LatLng local) {
    motoboysProximos.value = [
      Marker(
        markerId: const MarkerId('m1'),
        position: LatLng(local.latitude + 0.002, local.longitude + 0.002),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('m2'),
        position: LatLng(local.latitude - 0.003, local.longitude + 0.001),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    ];
  }

  Future<bool> solicitarMotoboy() async {
    final clinica = clinicaAtual.value;
    final lab = labDestino.value;

    if (clinica == null || lab == null) return false;

    try {
      isLoading.value = true;
      final novaColeta = Coleta(
        id: '#${DateTime.now().millisecondsSinceEpoch}',
        clinicaOrigem: clinica,
        laboratorioDestino: lab,
        status: 'Aguardando',
      );

      await _repository.solicitarColeta(novaColeta);
      return true;
    } catch (e) {
      debugPrint('Erro ao solicitar: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // 🧹 LIMPEZA DE MEMÓRIA (DISPOSE)
  // =========================================================================

  void dispose() {
    isLoading.dispose();
    clinicaAtual.dispose();
    labDestino.dispose();
    motoboysProximos.dispose();
    coletasEmTransito.dispose();
    todasClinicas.dispose();
  }
}
