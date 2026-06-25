import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';
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
// 1. ABA DASHBOARD
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
  // NOVO: Usamos um Set para permitir múltiplos filtros ativos ao mesmo tempo
  Set<String> _filtrosAtivos = {};

  late GoogleMapController mapController;

  BitmapDescriptor? _iconeLaboratorioCustom;
  BitmapDescriptor? _iconeMotoboyCustom;

  final LatLng _centroMapa = const LatLng(-23.550520, -46.633308);

  // NOVO: Dados atualizados com Paciente, Data Coleta, Data Recebimento e Tempo
  final List<Map<String, dynamic>> _todasColetas = [
    {
      'id': '00161',
      'clinica': 'Clínica Mundo Animal',
      'paciente': 'Rex (Golden Retriever)',
      'data_coleta': '26/06/2026 10:00',
      'data_recebimento': '-',
      'tempo': '-',
      'status': 'Aguardando',
      'motoboy': null,
      'cor': Colors.orange,
    },
    {
      'id': '00162',
      'clinica': 'Pet Shop Cão Feliz',
      'paciente': 'Mimi (Gato Persa)',
      'data_coleta': '26/06/2026 09:30',
      'data_recebimento': '-',
      'tempo': 'Em andamento',
      'status': 'A Caminho',
      'motoboy': 'Carlos Silva',
      'cor': Colors.blue,
    },
    {
      'id': '00163',
      'clinica': 'Hospital Vet Vida',
      'paciente': 'Thor (Bulldog)',
      'data_coleta': '25/06/2026 16:45',
      'data_recebimento': '25/06/2026 18:00',
      'tempo': '1h 15m',
      'status': 'Finalizada',
      'motoboy': 'Roberto Paz',
      'cor': Colors.green,
    },
    {
      'id': '00164',
      'clinica': 'Clínica São Francisco',
      'paciente': 'Nina (Poodle)',
      'data_coleta': '26/06/2026 11:15',
      'data_recebimento': '-',
      'tempo': 'Em andamento',
      'status': 'A Caminho',
      'motoboy': 'Ana Souza',
      'cor': Colors.blue,
    },
    {
      'id': '00165',
      'clinica': 'Vet Popular',
      'paciente': 'Bolinha (Pinscher)',
      'data_coleta': '26/06/2026 08:00',
      'data_recebimento': '26/06/2026 09:40',
      'tempo': '1h 40m',
      'status': 'Finalizada',
      'motoboy': 'Marcos Lima',
      'cor': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregarIconesCustomizados();
  }

  Future<Uint8List> _obterBytesDaImagem(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> _carregarIconesCustomizados() async {
    try {
      final Uint8List labBytes = await _obterBytesDaImagem(
        'assets/icons/lab_building.png',
        48,
      );
      final Uint8List motoBytes = await _obterBytesDaImagem(
        'assets/icons/motoboy.png',
        48,
      );

      setState(() {
        _iconeLaboratorioCustom = BitmapDescriptor.fromBytes(labBytes);
        _iconeMotoboyCustom = BitmapDescriptor.fromBytes(motoBytes);
      });
    } catch (e) {
      debugPrint(
        "Aviso: Imagens não encontradas. Verifique a pasta assets/icons. Erro: $e",
      );
    }
  }

  Set<Marker> _criarMarcadoresReais() {
    final iconLabFinal =
        _iconeLaboratorioCustom ?? BitmapDescriptor.defaultMarker;
    final iconMotoFinal = _iconeMotoboyCustom ?? BitmapDescriptor.defaultMarker;

    return {
      Marker(
        markerId: const MarkerId('lab_destino'),
        position: _centroMapa,
        infoWindow: InfoWindow(
          title: 'Laboratório QG: ${widget.laboratorio.nome}',
          snippet: 'Centro de Processamento',
        ),
        icon: iconLabFinal,
      ),
      Marker(
        markerId: const MarkerId('motoboy_carlos'),
        position: const LatLng(-23.542200, -46.641500),
        infoWindow: const InfoWindow(
          title: 'Carlos Silva',
          snippet: 'Rota: Clínica Mundo Animal',
        ),
        icon: iconMotoFinal,
      ),
      Marker(
        markerId: const MarkerId('motoboy_ana'),
        position: const LatLng(-23.558500, -46.624200),
        infoWindow: const InfoWindow(
          title: 'Ana Souza',
          snippet: 'Rota: Clínica São Francisco',
        ),
        icon: iconMotoFinal,
      ),
      Marker(
        markerId: const MarkerId('motoboy_roberto'),
        position: const LatLng(-23.545100, -46.621000),
        infoWindow: const InfoWindow(
          title: 'Roberto Paz',
          snippet: 'Retornando ao QG',
        ),
        icon: iconMotoFinal,
      ),
      Marker(
        markerId: const MarkerId('motoboy_marcos'),
        position: const LatLng(-23.561000, -46.645000),
        infoWindow: const InfoWindow(
          title: 'Marcos Lima',
          snippet: 'Aguardando liberação',
        ),
        icon: iconMotoFinal,
      ),
      Marker(
        markerId: const MarkerId('motoboy_juliana'),
        position: const LatLng(-23.535000, -46.631000),
        infoWindow: const InfoWindow(
          title: 'Juliana Costa',
          snippet: 'Coleta efetuada',
        ),
        icon: iconMotoFinal,
      ),
      Marker(
        markerId: const MarkerId('clinica_mundo_animal'),
        position: const LatLng(-23.565000, -46.652000),
        infoWindow: const InfoWindow(
          title: 'Clínica Mundo Animal',
          snippet: '1 Coleta Aguardando Retirada',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };
  }

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
                    filtroAlvo:
                        "Material", // Exemplo mantido do seu código original
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          _buildMapaSimulado(),
          const SizedBox(height: 32),
          _buildPainelColetas(),
        ],
      ),
    );
  }

  Widget _buildMapaSimulado() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _centroMapa,
                zoom: 13.0,
              ),
              markers: _criarMarcadoresReais(),
              myLocationEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.satellite_alt_rounded,
                      size: 16,
                      color: Colors.teal,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Monitor de Logística - Frota Ativa",
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

  Widget _buildKpiCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color corDestaque,
    required String descricao,
    required String filtroAlvo,
  }) {
    // NOVO: Verifica se o filtro está na nossa lista de ativos
    bool isSelecionado = _filtrosAtivos.contains(filtroAlvo);

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
          // NOVO: Adiciona ou remove do conjunto, permitindo múltiplos botões ativos
          setState(() {
            if (isSelecionado) {
              _filtrosAtivos.remove(filtroAlvo);
            } else {
              _filtrosAtivos.add(filtroAlvo);
            }
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
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
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

  Widget _buildPainelColetas() {
    // NOVO: Se o Set estiver vazio, mostra tudo. Caso contrário, mostra apenas os que batem com os filtros ativos
    List<Map<String, dynamic>> coletasExibidas = _filtrosAtivos.isEmpty
        ? _todasColetas
        : _todasColetas
              .where((coleta) => _filtrosAtivos.contains(coleta['status']))
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              // NOVO: Colunas atualizadas!
              columns: const [
                DataColumn(label: Text('ID Coleta')),
                DataColumn(label: Text('Clínica de Origem')),
                DataColumn(label: Text('Paciente')), // Nova Coluna
                DataColumn(label: Text('Data Coleta')), // Nome alterado
                DataColumn(label: Text('Data Recebimento')), // Nova Coluna
                DataColumn(label: Text('Tempo')), // Nova Coluna
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Motoboy')),
              ],
              rows: coletasExibidas
                  .map(
                    (coleta) => _criarLinhaTabela(
                      coleta['id'],
                      coleta['clinica'],
                      coleta['paciente'],
                      coleta['data_coleta'],
                      coleta['data_recebimento'],
                      coleta['tempo'],
                      coleta['status'],
                      coleta['motoboy'],
                      coleta['cor'],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icone, [Color? corDestaque]) {
    // NOVO: Lógica de seleção. "Todas" é ativo se a lista estiver vazia.
    bool isSelected = label == "Todas"
        ? _filtrosAtivos.isEmpty
        : _filtrosAtivos.contains(label);
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
          if (label == "Todas") {
            _filtrosAtivos.clear(); // Limpa todos os filtros
          } else {
            if (selected) {
              _filtrosAtivos.add(label); // Adiciona filtro
            } else {
              _filtrosAtivos.remove(label); // Remove filtro
            }
          }
        });
      },
    );
  }

  // NOVO: Assinatura do método alterada para receber as novas colunas
  DataRow _criarLinhaTabela(
    String id,
    String clinica,
    String paciente,
    String dataColeta,
    String dataRecebimento,
    String tempo,
    String status,
    String? motoboy,
    Color corStatus,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(clinica)),
        DataCell(Text(paciente)), // Nova célula inserida depois da clínica
        DataCell(Text(dataColeta)), // Célula alterada
        DataCell(Text(dataRecebimento)), // Nova Célula
        DataCell(Text(tempo)), // Nova Célula
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

class GestaoUsuariosLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const GestaoUsuariosLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class ConfiguracoesLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const ConfiguracoesLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
