import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/l10n/app_localizations.dart';

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

  Set<Polyline> _rotaAtiva = {};

  // Dados Mockados (Esses valores virão do banco depois, então não vão para o .arb)
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
      final i18n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.regSuccess), backgroundColor: Colors.green),
      );
    }
  }

  void _agendarColeta() {
    final i18n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n.clinicScheduleMock),
        backgroundColor: Colors.teal,
      ),
    );
  }

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

    mapController.animateCamera(CameraUpdate.newLatLngZoom(posMotoboy, 15.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!; // Dicionário ativo na tela

    return Scaffold(
      appBar: AppBar(
        title: Text(_minhaClinica.nome), // Nome dinâmico não precisa do i18n
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // === BLOCO 1: BOTÕES DE CHAMADA NO TOPO ===
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.teal.shade50,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, child) {
                return Row(
                  children: [
                    // Botão 1: Coleta Imediata
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
                            isLoading ? i18n.sending : i18n.immediate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botão 2: Coleta Agendada
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : _agendarColeta,
                          icon: const Icon(Icons.calendar_month, size: 22),
                          label: Text(
                            i18n.scheduled,
                            style: const TextStyle(
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
                final todosMarcadores = Set<Marker>.from(marcadores);
                todosMarcadores.add(
                  Marker(
                    markerId: const MarkerId('minha_clinica'),
                    position: _minhaClinica.endereco.coordenada!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueViolet,
                    ),
                    infoWindow: InfoWindow(title: i18n.clinicMarkerSelf),
                  ),
                );

                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _minhaClinica.endereco.coordenada!,
                    zoom: 14.5,
                  ),
                  markers: todosMarcadores,
                  polylines: _rotaAtiva,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    i18n.clinicTrackingTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
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
                          title: Text(
                            i18n.cliniCorrierSuccess,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                i18n.onWay,
                                style: const TextStyle(color: Colors.orange),
                              ),
                              Text(
                                i18n.clinicScheduleMock,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.my_location,
                            color: Colors.teal,
                          ),
                          isThreeLine: true,
                          onTap: () {
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
