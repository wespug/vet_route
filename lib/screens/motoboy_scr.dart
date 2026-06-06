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
            ),
          ),

          // === PARTE 3: O resto da tela (Lista de Entregas) ===
          // O Expanded faz essa lista preencher todo o espaço que sobrou na tela
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.motorcycle, color: Colors.orange),
                  title: Text('Coleta #001 - Clínica Vida Animal'),
                  subtitle: Text('Rua dos Cachorros, 123'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                ),
                Divider(), // Linha divisória
                ListTile(
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
