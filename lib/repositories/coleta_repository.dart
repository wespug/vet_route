// lib/repositories/coleta_repository.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/endereco_model.dart';

// O Contrato (Interface)
abstract class ColetaRepository {
  Future<List<Coleta>> buscarColetasNoRadar();
  Future<void> solicitarColeta(Coleta novaColeta);

  // NOVOS MÉTODOS DO CONTRATO
  Future<Clinica> obterClinicaLogada();
  Future<Laboratorio> obterLaboratorioPadrao();
}

// A Implementação Mock (Simulando o Backend com dados reais de SP)
class MockColetaRepository implements ColetaRepository {
  static final List<Coleta> _bancoDeDados = [
    Coleta(
      id: '#001',
      status: 'Aguardando',
      clinicaOrigem: Clinica(
        id: 'C001',
        nome: 'Hospital Veterinário Sena Madureira',
        telefone: '(11) 5572-8778',
        endereco: Endereco(
          nome: 'Sena Madureira',
          rua: 'Rua Sena Madureira, 898 - Vila Clementino',
          cep: '04021-001',
          cidade: 'São Paulo',
          estado: 'SP',
          pais: 'Brasil',
          pontoReferencia: 'Próximo à Cinemateca Brasileira',
          coordenada: const LatLng(
            -23.592520,
            -46.641680,
          ), // Coordenada real aproximada
        ),
      ),
      laboratorioDestino: Laboratorio(
        id: 'L001',
        nome: 'Provet - Unidade Aratãs',
        telefone: '(11) 5054-5800',
        endereco: Endereco(
          nome: 'Provet Moema',
          rua: 'Av. Aratãs, 1009 - Moema',
          cep: '04081-004',
          cidade: 'São Paulo',
          estado: 'SP',
          pais: 'Brasil',
          pontoReferencia: 'Próximo ao Shopping Ibirapuera',
          coordenada: const LatLng(-23.610530, -46.661040),
        ),
      ),
    ),
    Coleta(
      id: '#002',
      status: 'Aguardando',
      clinicaOrigem: Clinica(
        id: 'C002',
        nome: 'Pet Care - Unidade Ibirapuera',
        telefone: '(11) 3050-2273',
        endereco: Endereco(
          nome: 'Pet Care',
          rua: 'Av. República do Líbano, 270 - Ibirapuera',
          cep: '04502-000',
          cidade: 'São Paulo',
          estado: 'SP',
          pais: 'Brasil',
          coordenada: const LatLng(-23.582840, -46.659220),
        ),
      ),
      laboratorioDestino: Laboratorio(
        id: 'L002',
        nome: 'Gold Lab Vet',
        telefone: '(11) 3258-0000',
        endereco: Endereco(
          nome: 'Gold Lab',
          rua: 'R. Harry Dangos, 36 - Caxingui',
          cep: '05514-040',
          cidade: 'São Paulo',
          estado: 'SP',
          pais: 'Brasil',
          coordenada: const LatLng(-23.582450, -46.718810),
        ),
      ),
    ),
  ];

  @override
  Future<List<Coleta>> buscarColetasNoRadar() async {
    await Future.delayed(const Duration(seconds: 1));
    return _bancoDeDados.where((c) => c.status == 'Aguardando').toList();
  }

  @override
  Future<void> solicitarColeta(Coleta novaColeta) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _bancoDeDados.add(novaColeta);
  }

  @override
  @override
  Future<Clinica> obterClinicaLogada() async {
    // Simula a busca do usuário logado (ex: Auth service)
    await Future.delayed(const Duration(milliseconds: 300));
    return _bancoDeDados.first.clinicaOrigem;
  }

  @override
  Future<Laboratorio> obterLaboratorioPadrao() async {
    // Simula busca de laboratório preferencial
    await Future.delayed(const Duration(milliseconds: 300));
    return _bancoDeDados.first.laboratorioDestino;
  }
}
