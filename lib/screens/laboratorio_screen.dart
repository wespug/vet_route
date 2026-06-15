// lib/screens/laboratorio_scr.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/laboratorio_controller.dart';
import '../repositories/coleta_repository.dart';
import '../models/laboratorio_model.dart';
import '../models/endereco_model.dart';

class LaboratorioScreen extends StatefulWidget {
  const LaboratorioScreen({super.key});

  @override
  State<LaboratorioScreen> createState() => _LaboratorioScreenState();
}

class _LaboratorioScreenState extends State<LaboratorioScreen> {
  late GoogleMapController mapController;
  final LaboratorioController _controller = LaboratorioController(
    MockColetaRepository(),
  );

  // Dados Mockados do Laboratório logado
  final Laboratorio _meuLaboratorio = Laboratorio(
    id: 'L001',
    nome: 'Laboratório Central Vet Route',
    telefone: '(11) 4002-8922',
    endereco: Endereco(
      nome: 'Sede Laboratório',
      rua: 'Av. Brigadeiro Faria Lima, 2000',
      cep: '01451-000',
      cidade: 'São Paulo',
      estado: 'SP',
      pais: 'Brasil',
      coordenada: const LatLng(-23.576500, -46.686500),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.carregarDashboard(_meuLaboratorio.endereco.coordenada!);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _receberEncomendaMotoboy() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Iniciando recebimento... Escaneie o pacote.'),
        backgroundColor: Colors.indigo.shade600,
      ),
    );
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
        title: Text('Recepção - ${_meuLaboratorio.nome}'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDashboardCards(), // Painel no topo
          Expanded(child: _buildAreaDinamica()), // Mapa/Lista dependendo da aba
        ],
      ),
      // Botão inferior para receber o pacote
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _receberEncomendaMotoboy,
            icon: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
            label: const Text(
              'RECEBER PACOTE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === BLOCO 1: DASHBOARD DE NÚMEROS ===
  Widget _buildDashboardCards() {
    return Container(
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: ValueListenableBuilder<TabLabDashboard>(
        valueListenable: _controller.tabAtiva,
        builder: (context, tabAtiva, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _cardDash(
                titulo: 'Em Aberto',
                quantidade: '3', // Mockado (viria do controller)
                cor: Colors.redAccent,
                icone: Icons.access_time,
                ativo: tabAtiva == TabLabDashboard.emEspera,
                onTap: () => _controller.alterarTab(TabLabDashboard.emEspera),
              ),
              _cardDash(
                titulo: 'A Caminho',
                quantidade: '2',
                cor: Colors.blue,
                icone: Icons.local_shipping,
                ativo: tabAtiva == TabLabDashboard.aCaminho,
                onTap: () => _controller.alterarTab(TabLabDashboard.aCaminho),
              ),
              _cardDash(
                titulo: 'Finalizadas',
                quantidade: '18',
                cor: Colors.green,
                icone: Icons.fact_check_outlined,
                ativo: tabAtiva == TabLabDashboard.recebidas,
                onTap: () => _controller.alterarTab(TabLabDashboard.recebidas),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardDash({
    required String titulo,
    required String quantidade,
    required Color cor,
    required IconData icone,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ativo ? cor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo ? cor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: ativo
              ? [
                  BoxShadow(
                    color: cor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icone, color: ativo ? Colors.white : cor, size: 28),
            const SizedBox(height: 8),
            Text(
              quantidade,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ativo ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ativo ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === BLOCO 2: ÁREA DINÂMICA (MAPA OU LISTA) ===
  Widget _buildAreaDinamica() {
    return ValueListenableBuilder<TabLabDashboard>(
      valueListenable: _controller.tabAtiva,
      builder: (context, tabAtiva, child) {
        // CENA 1: ABA FINALIZADAS (Mostra apenas a lista)
        if (tabAtiva == TabLabDashboard.recebidas) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: 4, // Mockado
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 30,
                  ),
                  title: Text('Coleta #${900 - index} - Clínica Pet Feliz'),
                  subtitle: Text('Recebido às 1${index + 2}:45'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            },
          );
        }
        // CENA 2: ABA EM ABERTO (Divide a tela entre Mapa e Lista)
        else if (tabAtiva == TabLabDashboard.emEspera) {
          return Column(
            children: [
              Expanded(
                flex: 1, // O Mapa ocupa metade do espaço
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _meuLaboratorio.endereco.coordenada!,
                    zoom: 12.0,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('meu_lab'),
                      position: _meuLaboratorio.endereco.coordenada!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                      infoWindow: const InfoWindow(title: 'Laboratório'),
                    ),
                    // Mock de uma clínica esperando
                    Marker(
                      markerId: const MarkerId('clinica_esperando'),
                      position: LatLng(
                        _meuLaboratorio.endereco.coordenada!.latitude + 0.02,
                        _meuLaboratorio.endereco.coordenada!.longitude + 0.02,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: const InfoWindow(title: 'Coleta Aguardando'),
                    ),
                  },
                ),
              ),
              Expanded(
                flex: 1, // A Lista ocupa a outra metade
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(
                        Icons.warning_amber,
                        color: Colors.redAccent,
                      ),
                      title: Text('Aguardando Motoboy'),
                      subtitle: Text('Clínica Central - Feito há 15 min'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        // CENA 3: ABA A CAMINHO (Mapa completo focado no Radar do Lab)
        else {
          return ValueListenableBuilder<List<Marker>>(
            valueListenable: _controller.motoboysACaminho,
            builder: (context, motoboys, child) {
              final radar = Set<Marker>.from(motoboys);
              radar.add(
                Marker(
                  markerId: const MarkerId('meu_lab'),
                  position: _meuLaboratorio.endereco.coordenada!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: const InfoWindow(title: 'Seu Laboratório'),
                ),
              );

              return Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _meuLaboratorio.endereco.coordenada!,
                      zoom: 14.0,
                    ),
                    markers: radar,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.white.withValues(alpha: 0.9),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Radar do Laboratório: Acompanhando motoboys a caminho em tempo real.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}
