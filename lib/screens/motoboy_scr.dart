import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Importante adicionar o pacote do mapa!

class MotoboyScreen extends StatefulWidget {
  const MotoboyScreen({super.key});

  @override
  State<MotoboyScreen> createState() => _MotoboyScreenState();
}

class _MotoboyScreenState extends State<MotoboyScreen> {
  // Controlador do mapa (usado para mover a câmera depois, se precisarmos)
  late GoogleMapController mapController;

  // Posição inicial do mapa (Ex: Centro de São Paulo. Depois vamos mudar para o GPS do celular)
  final LatLng _center = const LatLng(-23.550520, -46.633308);
  Set<Marker> _marcadores = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Motoboy'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // === PARTE 1: Cabeçalho da tela ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Rotas de Hoje',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // === PARTE 2: O Mapa (ocupando uma parte fixa da tela) ===
          // Usamos o SizedBox para travar a altura do mapa em 300 pixels
          SizedBox(
            height: 300,
            width: double.infinity, // Ocupa toda a largura da tela
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0, // Nível do zoom (quanto maior, mais perto da rua)
              ),
              myLocationEnabled:
                  true, // Mostra o ponto azul do GPS (se tiver permissão)
              myLocationButtonEnabled:
                  true, // Botão de centralizar na localização
              markers: _marcadores,
            ),
          ),

          // === PARTE 3: O resto da tela (Lista de Entregas) ===
          Expanded(
            child: ListView(
              children: [
                // <-- REMOVA A PALAVRA 'const' DESTA LINHA!
                ListTile(
                  leading: const Icon(Icons.motorcycle, color: Colors.orange),
                  title: const Text('Coleta #001 - Clínica Vida Animal'),
                  subtitle: const Text('Rua dos Cachorros, 123'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _marcadores = {
                        Marker(
                          // <-- Pode tirar o 'const' daqui também, se tiver
                          markerId: const MarkerId('origem'),
                          position: const LatLng(-23.550520, -46.633308),
                          infoWindow: const InfoWindow(
                            title: 'Coleta: Clínica Vida Animal',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                        Marker(
                          // <-- E daqui
                          markerId: const MarkerId('destino'),
                          position: const LatLng(-23.560520, -46.643308),
                          infoWindow: const InfoWindow(
                            title: 'Entrega: Laboratório Central',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      };
                    });

                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(-23.550520, -46.633308),
                        13.5,
                      ),
                    );
                  },
                ),
                const Divider(),
                const ListTile(
                  // Nos itens de baixo que não têm 'onTap' ainda, você pode deixar o const
                  leading: Icon(Icons.motorcycle, color: Colors.orange),
                  title: Text('Entrega #002 - Laboratório Central'),
                  subtitle: Text('Avenida dos Felinos, 456'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
