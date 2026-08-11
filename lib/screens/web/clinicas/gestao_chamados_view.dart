import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/screens/web/clinicas/components/chamados_data_source.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_pedir_insumos.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_novo_chamado.dart';

class GestaoChamadosView extends StatefulWidget {
  final Clinica clinicaContexto;

  const GestaoChamadosView({super.key, required this.clinicaContexto});

  @override
  State<GestaoChamadosView> createState() => _GestaoChamadosViewState();
}

class _GestaoChamadosViewState extends State<GestaoChamadosView>
    with TickerProviderStateMixin {
  final ChamadoColetaController _controller = ChamadoColetaController();

  String _termoBusca = '';
  int _linhasPorPagina = PaginatedDataTable.defaultRowsPerPage;

  // Controle de Ordenação
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _controller.carregarChamados(widget.clinicaContexto.id!);
    _controller.carregarLaboratorios();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _obterUsuarioLogado() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email ?? 'Usuário');
    }
    return 'Usuário Desconhecido';
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBarraSuperior(),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por laboratório ou status da coleta...',
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.indigo,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) => setState(() => _termoBusca = value),
              ),
              const SizedBox(height: 24),
              const TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: "Coletas Ativas & Agendadas"),
                  Tab(text: "Encerrados / Histórico"),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildListaChamados(isHistorico: false),
                    _buildListaChamados(isHistorico: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraSuperior() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Gestão de Coletas 📦",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Painel logístico operacional da ${widget.clinicaContexto.nome}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => ModalPedirInsumos(
                  controller: _controller,
                  clinicaContexto: widget.clinicaContexto,
                  usuarioLogado: _obterUsuarioLogado(),
                ),
              ),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text(
                "Pedir Insumos",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ModalNovoChamado(
                  isEmergencia: false,
                  controller: _controller,
                  clinicaContexto: widget.clinicaContexto,
                ),
              ),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                "Coleta Agendada",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ModalNovoChamado(
                  isEmergencia: true,
                  controller: _controller,
                  clinicaContexto: widget.clinicaContexto,
                ),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text(
                "Coleta de Urgência",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                backgroundColor: Colors.redAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListaChamados({required bool isHistorico}) {
    final listenableTarget = isHistorico
        ? _controller.chamadosPassados
        : _controller.chamadosHoje;

    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );
        }

        return ValueListenableBuilder<List<ChamadoColetaModel>>(
          valueListenable: listenableTarget,
          builder: (context, chamados, child) {
            // 1. Filtragem por busca e garantia de separação por status
            List<ChamadoColetaModel> chamadosFiltrados = chamados.where((c) {
              final statusLower = c.status.toLowerCase();
              final eEncerrado =
                  statusLower == 'entregue' ||
                  statusLower == 'concluído' ||
                  statusLower == 'cancelado' ||
                  statusLower == 'recusado' ||
                  statusLower == 'finalizada';

              // Filtra se deve aparecer na aba atual
              if (isHistorico && !eEncerrado) return false;
              if (!isHistorico && eEncerrado) return false;

              // Filtra pelo termo buscado
              final termo = _termoBusca.toLowerCase();
              return c.laboratorioNome.toLowerCase().contains(termo) ||
                  c.status.toLowerCase().contains(termo);
            }).toList();

            // 2. Lógica de Ordenação em Memória
            if (_sortColumnIndex != null) {
              chamadosFiltrados.sort((a, b) {
                int comp = 0;
                switch (_sortColumnIndex) {
                  case 1:
                    comp = a.laboratorioNome.compareTo(b.laboratorioNome);
                    break;
                  case 2:
                    comp = a.dataAgendamento.compareTo(b.dataAgendamento);
                    break;
                  case 3:
                    comp = a.status.compareTo(b.status);
                    break;
                }
                return _sortAscending ? comp : -comp;
              });
            }

            if (chamadosFiltrados.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isHistorico
                          ? Icons.history_rounded
                          : Icons.inventory_2_outlined,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _termoBusca.isNotEmpty
                          ? "Nenhuma coleta encontrada para '$_termoBusca'."
                          : (isHistorico
                                ? "Nenhum histórico de coletas e pedidos."
                                : "Nenhuma coleta ativa ou agendada."),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final dataSource = ChamadosDataSource(
              context: context,
              chamados: chamadosFiltrados,
              clinicaContexto: widget.clinicaContexto,
              usuarioLogado: _obterUsuarioLogado(),
            );

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  header: Text(
                    isHistorico
                        ? "Histórico Operacional / Encerrados"
                        : "Painel de Coletas Ativas",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  rowsPerPage: _linhasPorPagina,
                  availableRowsPerPage: const [5, 10, 20, 50],
                  onRowsPerPageChanged: (value) => setState(
                    () => _linhasPorPagina =
                        value ?? PaginatedDataTable.defaultRowsPerPage,
                  ),
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columns: [
                    const DataColumn(
                      label: Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: const Text(
                        'Laboratório Destino',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    const DataColumn(
                      label: Text(
                        'Ações',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  source: dataSource,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
