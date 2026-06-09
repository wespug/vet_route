// lib/screens/clinica_scr.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/clinica_controller.dart';
import '../repositories/coleta_repository.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/endereco_model.dart';

class ClinicaScreen extends StatefulWidget {
  const ClinicaScreen({super.key});

  @override
  State<ClinicaScreen> createState() => _ClinicaScreenState();
}

class _ClinicaScreenState extends State<ClinicaScreen> {
  // Instanciando a controladora com o repositório
  final ClinicaController _controller = ClinicaController(
    MockColetaRepository(),
  );

  // Dados Mockados de quem está logado (A Clínica) e para onde vai enviar
  final Clinica _minhaClinica = Clinica(
    id: 'C999',
    nome: 'Clínica Vet Route Oficial',
    telefone: '(11) 5555-5555',
    endereco: Endereco(
      nome: 'Sede Vet Route',
      rua: 'Av. Paulista, 1000',
      cep: '01310-100',
      cidade: 'São Paulo',
      estado: 'SP',
      pais: 'Brasil',
      coordenada: const LatLng(-23.565310, -46.651710),
    ),
  );

  final Laboratorio _labDestino = Laboratorio(
    id: 'L999',
    nome: 'Laboratório Vet Route Express',
    telefone: '(11) 4444-4444',
    endereco: Endereco(
      nome: 'Lab Express',
      rua: 'Rua Augusta, 500',
      cep: '01304-000',
      cidade: 'São Paulo',
      estado: 'SP',
      pais: 'Brasil',
      coordenada: const LatLng(-23.553950, -46.651260),
    ),
  );

  void _chamarMotoboy() async {
    final sucesso = await _controller.solicitarMotoboy(
      _minhaClinica,
      _labDestino,
    );

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motoboy solicitado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área da Clínica'),
        backgroundColor:
            Colors.teal, // Cor diferente para identificar a clínica
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                'Olá, ${_minhaClinica.nome}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tem exames prontos para enviar? Solicite um motoboy agora mesmo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Botão reativo que escuta o estado de Loading
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoading,
                builder: (context, isLoading, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : _chamarMotoboy,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.motorcycle, color: Colors.white),
                      label: Text(
                        isLoading ? 'Localizando motoboy...' : 'Chamar Motoboy',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
