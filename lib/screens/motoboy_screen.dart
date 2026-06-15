// lib/screens/motoboy_scr.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/coleta_controller.dart';
import '../repositories/coleta_repository.dart';
import '../models/coleta_model.dart';

class MotoboyScreen extends StatefulWidget {
  const MotoboyScreen({super.key});

  @override
  State<MotoboyScreen> createState() => _MotoboyScreenState();
}

class _MotoboyScreenState extends State<MotoboyScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(-23.550520, -46.633308);

  Set<Marker> _marcadores = {};
  Set<Polyline> _rotas = {};

  // Instanciando a Controladora injetando o Repositório Mock
  final ColetaController _controller = ColetaController(MockColetaRepository());

  @override
  void initState() {
    super.initState();
    // EXATAMENTE AQUI: Quando o motoboy entra na tela, a controladora busca os dados
    _controller.carregarColetas();
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Protege o app contra vazamento de memória (Memory Leak)
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Motoboy (MVC)'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Coletas no seu Radar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // PARTE 2: O Mapa
          SizedBox(
            height: 300,
            width: double.infinity,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _marcadores,
              polylines: _rotas,
            ),
          ),

          // PARTE 3: Lista Dinâmica Reativa controlada pela Controladora
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, child) {
                // Se a controladora disser que está carregando, mostra o indicador de progresso
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                // Se não estiver carregando, escuta a lista de coletas
                return ValueListenableBuilder<List<Coleta>>(
                  valueListenable: _controller.coletasNoRadar,
                  builder: (context, listaColetas, child) {
                    if (listaColetas.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma coleta no radar no momento.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: listaColetas.length,
                      itemBuilder: (context, index) {
                        final coleta = listaColetas[index];

                        return Column(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.motorcycle,
                                color: Colors.orange,
                              ),
                              title: Text(
                                'Coleta ${coleta.id} - ${coleta.clinicaOrigem.nome}',
                              ),
                              subtitle: Text(coleta.clinicaOrigem.endereco.rua),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                setState(() {
                                  _marcadores = {
                                    Marker(
                                      markerId: const MarkerId('origem'),
                                      position: coleta
                                          .clinicaOrigem
                                          .endereco
                                          .coordenada!,
                                      infoWindow: InfoWindow(
                                        title:
                                            'Coleta: ${coleta.clinicaOrigem.nome}',
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueBlue,
                                          ),
                                    ),
                                    Marker(
                                      markerId: const MarkerId('destino'),
                                      position: coleta
                                          .laboratorioDestino
                                          .endereco
                                          .coordenada!,
                                      infoWindow: InfoWindow(
                                        title:
                                            'Entrega: ${coleta.laboratorioDestino.nome}',
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueRed,
                                          ),
                                    ),
                                  };

                                  _rotas = {
                                    Polyline(
                                      polylineId: const PolylineId(
                                        'rota_dinamica',
                                      ),
                                      color: Colors.blueAccent,
                                      width: 5,
                                      points: [
                                        coleta
                                            .clinicaOrigem
                                            .endereco
                                            .coordenada!,
                                        coleta
                                            .laboratorioDestino
                                            .endereco
                                            .coordenada!,
                                      ],
                                    ),
                                  };
                                });

                                mapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    coleta.clinicaOrigem.endereco.coordenada!,
                                    13.5,
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
