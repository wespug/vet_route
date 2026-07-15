import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_detalhes_coleta.dart';

import 'package:vet_route/screens/web/clinicas/modalR/modal_detalhes_insumo.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_pedir_insumos.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_novo_chamado.dart';
// 💡 MÁGICA: Importando o novo modal de Coleta
import 'package:vet_route/screens/web/clinicas/modal/modal_detalhes_coleta.dart';

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
                  Tab(text: "Coletas Entregues / Histórico"),
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
        if (isLoading)
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );

        return ValueListenableBuilder<List<ChamadoColetaModel>>(
          valueListenable: listenableTarget,
          builder: (context, chamados, child) {
            List<ChamadoColetaModel> chamadosFiltrados = chamados.where((c) {
              final termo = _termoBusca.toLowerCase();
              return c.laboratorioNome.toLowerCase().contains(termo) ||
                  c.status.toLowerCase().contains(termo);
            }).toList();

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
                        ? "Histórico Operacional"
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
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Laboratório Destino',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
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

class ChamadosDataSource extends DataTableSource {
  final BuildContext context;
  final List<ChamadoColetaModel> chamados;
  final Clinica clinicaContexto;
  final String usuarioLogado;

  ChamadosDataSource({
    required this.context,
    required this.chamados,
    required this.clinicaContexto,
    required this.usuarioLogado,
  });

  static Color obterCorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aguardando entregador':
      case 'pendente':
        return Colors.orange;
      case 'a caminho':
        return Colors.blue;
      case 'aguardando insumos':
      case 'aprovado':
        return Colors.teal;
      case 'concluído':
      case 'finalizada':
      case 'entregue':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  DataRow? getRow(int index) {
    if (index >= chamados.length) return null;
    final chamado = chamados[index];

    final String dataFormatada =
        "${chamado.dataAgendamento.day.toString().padLeft(2, '0')}/${chamado.dataAgendamento.month.toString().padLeft(2, '0')}/${chamado.dataAgendamento.year}";
    final corStatus = obterCorStatus(chamado.status);
    final bool isInsumo = chamado.laboratorioId.startsWith('INSUMO_');

    IconData iconeTipo;
    Color corTipo;
    Color corFundoTipo;

    if (isInsumo) {
      iconeTipo = Icons.inventory_2_rounded;
      corTipo = Colors.teal;
      corFundoTipo = Colors.teal.shade50;
    } else if (chamado.isEmergencia) {
      iconeTipo = Icons.flash_on_rounded;
      corTipo = Colors.redAccent.shade700;
      corFundoTipo = Colors.red.shade50;
    } else {
      iconeTipo = Icons.motorcycle_rounded;
      corTipo = Colors.indigo;
      corFundoTipo = Colors.indigo.shade50;
    }

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: corFundoTipo,
              shape: BoxShape.circle,
            ),
            child: Icon(iconeTipo, color: corTipo, size: 20),
          ),
        ),
        DataCell(
          Text(
            chamado.laboratorioNome,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ),
        DataCell(Text(dataFormatada)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: corStatus.withOpacity(0.5)),
            ),
            child: Text(
              chamado.status.toUpperCase(),
              style: TextStyle(
                color: corStatus,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
            onPressed: () {
              if (isInsumo) {
                showDialog(
                  context: context,
                  builder: (_) => ModalDetalhesInsumo(
                    chamado: chamado,
                    clinicaContexto: clinicaContexto,
                    usuarioLogado: usuarioLogado,
                    obterCorStatus: obterCorStatus,
                  ),
                );
              } else {
                // 💡 MÁGICA: Agora as coletas normais também chamam seu próprio Modal de Elite!
                showDialog(
                  context: context,
                  builder: (_) => ModalDetalhesColeta(
                    chamado: chamado,
                    clinicaContexto: clinicaContexto,
                    usuarioLogado: usuarioLogado,
                    obterCorStatus: obterCorStatus,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => chamados.length;
  @override
  int get selectedRowCount => 0;
}
