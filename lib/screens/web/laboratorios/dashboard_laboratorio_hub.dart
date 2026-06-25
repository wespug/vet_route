import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/models/laboratorio_model.dart';

import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';

// 💡 A MÁGICA QUE APAGA O ERRO: Importando a biblioteca do Google Maps
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetalheLaboratorioHub extends StatelessWidget {
  final Laboratorio laboratorio;

  const DetalheLaboratorioHub({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO COM AS ABAS
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: "Dashboard"),
                Tab(icon: Icon(Icons.people_alt_outlined), text: "Usuários"),
                Tab(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  text: "Gestão",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // O CONTEÚDO DAS ABAS
          Expanded(
            child: TabBarView(
              children: [
                DashboardLaboratorioView(laboratorio: laboratorio),
                GestaoUsuariosLaboratorioView(laboratorio: laboratorio),
                ConfiguracoesLaboratorioView(laboratorio: laboratorio),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. ABA DASHBOARD (Com Mapa e Tabela Interativa)
// ============================================================================
class DashboardLaboratorioView extends StatefulWidget {
  final Laboratorio laboratorio;
  const DashboardLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  State<DashboardLaboratorioView> createState() =>
      _DashboardLaboratorioViewState();
}

class _DashboardLaboratorioViewState extends State<DashboardLaboratorioView> {
  // Variável que guarda em qual cartão/filtro o usuário clicou
  String _filtroAtual = "Todas";

  // Dados Falsos para a Tabela e Filtros
  final List<Map<String, dynamic>> _todasColetas = [
    {
      'id': '00161',
      'clinica': 'Clínica Mundo Animal',
      'data': '26/06/2026 10:00',
      'status': 'Aguardando',
      'motoboy': null,
      'cor': Colors.orange,
    },
    {
      'id': '00162',
      'clinica': 'Pet Shop Cão Feliz',
      'data': '26/06/2026 09:30',
      'status': 'A Caminho',
      'motoboy': 'Carlos Silva',
      'cor': Colors.blue,
    },
    {
      'id': '00163',
      'clinica': 'Hospital Vet Vida',
      'data': '25/06/2026 16:45',
      'status': 'Finalizada',
      'motoboy': 'Roberto Paz',
      'cor': Colors.green,
    },
    {
      'id': '00164',
      'clinica': 'Clínica São Francisco',
      'data': '26/06/2026 11:15',
      'status': 'A Caminho',
      'motoboy': 'Ana Souza',
      'cor': Colors.blue,
    },
    {
      'id': '00165',
      'clinica': 'Vet Popular',
      'data': '26/06/2026 08:00',
      'status': 'Finalizada',
      'motoboy': 'Marcos Lima',
      'cor': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard de Operações",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // GRID DOS CARDS (KPIs)
          LayoutBuilder(
            builder: (context, constraints) {
              int colunas = constraints.maxWidth > 1200
                  ? 4
                  : (constraints.maxWidth > 800 ? 2 : 1);

              return GridView.count(
                crossAxisCount: colunas,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _buildKpiCard(
                    titulo: "Coletas Solicitadas",
                    valor: "12",
                    icone: Icons.assignment_outlined,
                    corDestaque: Colors.orange,
                    descricao: "Aguardando atribuição",
                    filtroAlvo: "Aguardando",
                  ),
                  _buildKpiCard(
                    titulo: "Coletas a Caminho",
                    valor: "5",
                    icone: Icons.motorcycle_outlined,
                    corDestaque: Colors.blue,
                    descricao: "Motoboys em trânsito",
                    filtroAlvo: "A Caminho",
                  ),
                  _buildKpiCard(
                    titulo: "Coletas Recebidas",
                    valor: "48",
                    icone: Icons.check_circle_outline,
                    corDestaque: Colors.green,
                    descricao: "Hoje (Finalizadas)",
                    filtroAlvo: "Finalizada",
                  ),
                  _buildKpiCard(
                    titulo: "Material Solicitado",
                    valor: "3",
                    icone: Icons.inventory_2_outlined,
                    corDestaque: Colors.purple,
                    descricao: "Kits e tubos pendentes",
                    filtroAlvo: "Material",
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // 📍 O QUADRADINHO DO MAPA (Simulador de Logística)
          _buildMapaSimulado(),

          const SizedBox(height: 32),

          // O PAINEL DE COLETAS (Com Botões de Filtro e Tabela)
          _buildPainelColetas(),
        ],
      ),
    );
  }

  // ==================== WIDGETS DO DASHBOARD ====================

  Widget _buildKpiCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color corDestaque,
    required String descricao,
    required String filtroAlvo,
  }) {
    bool isSelecionado = _filtroAtual == filtroAlvo;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelecionado ? corDestaque : Colors.grey.shade300,
          width: isSelecionado ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            // Se clicar no que já está selecionado, ele limpa e mostra "Todas"
            _filtroAtual = isSelecionado ? "Todas" : filtroAlvo;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: corDestaque.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icone, size: 32, color: corDestaque),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                descricao,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // O MAPA REAL DO GOOGLE MAPS
  // ==========================================================

  late GoogleMapController mapController;

  // Centro do Mapa (Ex: Avenida Paulista, São Paulo - Ajuste para o seu Laboratório)
  final LatLng _centroMapa = const LatLng(-23.550520, -46.633308);

  // Função para criar os Pinos Reais no Google Maps
  Set<Marker> _criarMarcadoresReais() {
    return {
      // Pino do Laboratório
      Marker(
        markerId: const MarkerId('lab_destino'),
        position: const LatLng(-23.550520, -46.633308),
        infoWindow: InfoWindow(
          title: 'Laboratório Destino: ${widget.laboratorio.nome}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueTeal,
        ), // Cor Teal
      ),
      // Pino do Motoboy 1
      const Marker(
        markerId: MarkerId('motoboy_carlos'),
        position: LatLng(-23.540000, -46.640000),
        infoWindow: InfoWindow(
          title: 'Motoboy: Carlos',
          snippet: 'A caminho (5 min)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ), // Cor Azul
      ),
      // Pino da Clínica
      const Marker(
        markerId: MarkerId('clinica_mundo_animal'),
        position: LatLng(-23.560000, -46.650000),
        infoWindow: InfoWindow(
          title: 'Clínica Mundo Animal',
          snippet: 'Coleta Aguardando',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ), // Cor Laranja
      ),
    };
  }

  Widget _buildMapaSimulado() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Fundo enquanto o mapa carrega
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // O ClipRRect garante que o Google Maps não fure as bordas arredondadas da nossa moldura
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // O WIDGET REAL DO GOOGLE MAPS
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _centroMapa,
                zoom: 13.5, // Nível de zoom da cidade
              ),
              markers: _criarMarcadoresReais(),
              myLocationEnabled:
                  false, // Pode ligar quando tiver permissão de GPS
              mapToolbarEnabled: false, // Desliga botões feios nativos do Maps
              zoomControlsEnabled: false,
            ),

            // O nosso título flutuante elegante mantido por cima do mapa real
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min, // Ocupa apenas o espaço necessário
                  children: [
                    Icon(
                      Icons.satellite_alt_rounded,
                      size: 16,
                      color: Colors.teal,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Monitor de Logística - Google Maps Live",
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PAINEL E TABELA ====================

  Widget _buildPainelColetas() {
    // Lógica para filtrar a lista com base no botão clicado
    List<Map<String, dynamic>> coletasExibidas =
        _filtroAtual == "Todas" || _filtroAtual == "Material"
        ? _todasColetas
        : _todasColetas
              .where((coleta) => coleta['status'] == _filtroAtual)
              .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho e 4 BOTÕES DE FILTRO (Chips)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Painel de Coletas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip("Todas", Icons.list),
                    _buildFilterChip(
                      "Aguardando",
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _buildFilterChip(
                      "A Caminho",
                      Icons.motorcycle,
                      Colors.blue,
                    ),
                    _buildFilterChip(
                      "Finalizada",
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tabela Interativa
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              columns: const [
                DataColumn(label: Text('ID Coleta')),
                DataColumn(label: Text('Clínica de Origem')),
                DataColumn(label: Text('Data/Hora')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Motoboy')),
              ],
              rows: coletasExibidas.map((coleta) {
                return _criarLinhaTabela(
                  coleta['id'],
                  coleta['clinica'],
                  coleta['data'],
                  coleta['status'],
                  coleta['motoboy'],
                  coleta['cor'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET DO BOTÃO DE FILTRO (CHIP)
  Widget _buildFilterChip(String label, IconData icone, [Color? corDestaque]) {
    bool isSelected = _filtroAtual == label;
    Color corAtiva = corDestaque ?? Theme.of(context).primaryColor;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: Icon(
        icone,
        size: 18,
        color: isSelected ? Colors.white : (corDestaque ?? Colors.grey),
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: corAtiva,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (bool selected) {
        setState(() {
          _filtroAtual = selected ? label : "Todas";
        });
      },
    );
  }

  // FUNÇÃO DA LINHA DA TABELA
  DataRow _criarLinhaTabela(
    String id,
    String clinica,
    String data,
    String status,
    String? motoboy,
    Color corStatus,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(clinica)),
        DataCell(Text(data)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: corStatus,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            motoboy ?? 'Não atribuído',
            style: TextStyle(
              color: motoboy == null ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. ABA GESTÃO DE USUÁRIOS (Placeholder)
// ============================================================================
class GestaoUsuariosLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const GestaoUsuariosLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Membros da Equipe",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text("Novo Usuário"),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.blueGrey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhum usuário vinculado ainda.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ABA CONFIGURAÇÕES (Placeholder)
// ============================================================================
class ConfiguracoesLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const ConfiguracoesLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Configurações Administrativas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.orange),
            title: const Text("Editar Perfil"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Desativar Laboratório"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
