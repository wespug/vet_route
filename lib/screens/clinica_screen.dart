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
  late GoogleMapController mapController;
  final ClinicaController _controller = ClinicaController(
    MockColetaRepository(),
  );

  Set<Polyline> _rotaAtiva = {}; // Para traçar a rota do motoboy até a clínica

  // Dados Mockados da Clínica
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

  @override
  void initState() {
    super.initState();
    // Carrega o mapa tático da clínica assim que a tela abre
    _controller.carregarPainelLogistico(_minhaClinica.endereco.coordenada!);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _chamarMotoboy() async {
    final sucesso = await _controller.solicitarMotoboy(
      _minhaClinica,
      _labDestino,
    );
    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motoboy solicitado! Aguardando aceite.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _agendarColeta() {
    // No futuro, isso abrirá um DatePicker/TimePicker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo calendário para agendamento...'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  // Simula o clique na coleta ativa para ver a rota
  void _acompanharCorrida(LatLng posMotoboy) {
    setState(() {
      _rotaAtiva = {
        Polyline(
          polylineId: const PolylineId('rota_rastreio'),
          color: Colors.teal,
          width: 5,
          points: [posMotoboy, _minhaClinica.endereco.coordenada!],
        ),
      };
    });

    // Anima a câmera para o meio do caminho entre o motoboy e a clínica
    mapController.animateCamera(CameraUpdate.newLatLngZoom(posMotoboy, 15.0));
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
        title: Text(_minhaClinica.nome),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // === BLOCO 1: BOTÃO DE CHAMADA NO TOPO ===
          // === BLOCO 1: BOTÕES DE CHAMADA NO TOPO ===
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.teal.shade50,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, child) {
                return Row(
                  children: [
                    // Botão 1: Coleta Imediata (Principal)
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                              : const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 22,
                                ),
                          label: Text(
                            isLoading ? 'Enviando...' : 'IMEDIATA',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Espaçamento entre os botões
                    // Botão 2: Coleta Agendada (Secundário)
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Colors.teal, // Cor do texto e ícone
                            side: const BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ), // Borda
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : _agendarColeta,
                          icon: const Icon(Icons.calendar_month, size: 22),
                          label: const Text(
                            'AGENDADA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // === BLOCO 2: MAPA TÁTICO ===
          SizedBox(
            height: 300,
            width: double.infinity,
            child: ValueListenableBuilder<List<Marker>>(
              valueListenable: _controller.motoboysProximos,
              builder: (context, marcadores, child) {
                // Adicionamos o pino da própria clínica no mapa
                final todosMarcadores = Set<Marker>.from(marcadores);
                todosMarcadores.add(
                  Marker(
                    markerId: const MarkerId('minha_clinica'),
                    position: _minhaClinica.endereco.coordenada!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueViolet,
                    ),
                    infoWindow: const InfoWindow(title: 'Sua Clínica'),
                  ),
                );

                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _minhaClinica.endereco.coordenada!,
                    zoom: 14.5,
                  ),
                  markers: todosMarcadores,
                  polylines: _rotaAtiva, // Desenha a rota de rastreio se houver
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                );
              },
            ),
          ),

          // === BLOCO 3: LISTA DE ACOMPANHAMENTO EM TEMPO REAL ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Acompanhamento em Tempo Real',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Simulação de uma coleta a caminho da clínica (Mock visual)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.motorcycle, color: Colors.white),
                          ),
                          title: const Text(
                            'Coleta #882 - Carlos (Motoboy)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                'Status: A caminho da Clínica',
                                style: TextStyle(color: Colors.orange),
                              ),
                              Text(
                                '⏳ Est: 12 min | Decorrido: 5 min',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.my_location,
                            color: Colors.teal,
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Clicou? Foca no motoboy e traça a rota!
                            // (Aqui simulamos o motoboy 'm1' se aproximando)
                            _acompanharCorrida(
                              LatLng(
                                _minhaClinica.endereco.coordenada!.latitude +
                                    0.002,
                                _minhaClinica.endereco.coordenada!.longitude +
                                    0.002,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
