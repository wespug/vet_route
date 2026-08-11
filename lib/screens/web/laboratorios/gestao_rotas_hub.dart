import 'package:flutter/material.dart';
import 'package:vet_route/controllers/rota_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/rota_model.dart';
import 'package:vet_route/view/rotas/widgets/modal_cadastro_rota_dialog.dart';

class GestaoRotasHub extends StatefulWidget {
  final Laboratorio labContexto;

  const GestaoRotasHub({super.key, required this.labContexto});

  @override
  State<GestaoRotasHub> createState() => _GestaoRotasHubState();
}

class _GestaoRotasHubState extends State<GestaoRotasHub> {
  final RotaController _controller = RotaController();

  String _termoBusca = '';
  int _linhasPorPagina = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _controller.carregarRotas(widget.labContexto.id ?? '');
    _controller.inicializarDadosFormulario();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _abrirModalRota([RotaModel? rotaAtual]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalCadastroRotaDialog(
        controller: _controller,
        labContexto: widget.labContexto,
        rotaAtual: rotaAtual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Roteirização Logística 🗺️",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mapeie rotas fixas de coleta para os motoboys da base ${widget.labContexto.nome}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalRota(),
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text(
                  "Nova Rota Fixa",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CAMPO DE BUSCA
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nome do motoboy...',
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => _termoBusca = value),
          ),
          const SizedBox(height: 24),

          // TABELA DE ROTAS
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, _) {
                if (isLoading)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  );

                return ValueListenableBuilder<List<RotaModel>>(
                  valueListenable: _controller.rotas,
                  builder: (context, rotas, _) {
                    List<RotaModel> rotasFiltradas = rotas.where((r) {
                      return r.nomeEntregador.toLowerCase().contains(
                        _termoBusca.toLowerCase(),
                      );
                    }).toList();

                    final dataSource = _RotasDataSource(
                      rotas: rotasFiltradas,
                      onEdit: (rota) => _abrirModalRota(rota),
                      onDelete: (rota) => _confirmarExclusaoRota(rota),
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
                          header: const Text(
                            "Lista de Rotas Operacionais",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          rowsPerPage: _linhasPorPagina,
                          availableRowsPerPage: const [5, 10, 20, 50],
                          onRowsPerPageChanged: (v) => setState(
                            () => _linhasPorPagina =
                                v ?? PaginatedDataTable.defaultRowsPerPage,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Motoboy Designado',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status da Rota',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Qtd. Paradas',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Resumo do Trajeto',
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
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusaoRota(RotaModel rota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Rota"),
        content: Text(
          "Tem certeza que deseja excluir a rota do motoboy ${rota.nomeEntregador}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (rota.id != null) {
                await _controller.deletarRota(
                  rota.id!,
                  widget.labContexto.id ?? '',
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// DATA SOURCE
class _RotasDataSource extends DataTableSource {
  final List<RotaModel> rotas;
  final Function(RotaModel) onEdit;
  final Function(RotaModel) onDelete;

  _RotasDataSource({
    required this.rotas,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= rotas.length) return null;
    final rota = rotas[index];
    final resumoTrajeto = rota.paradas.map((p) => p.nomeClinica).join(" ➔ ");

    return DataRow(
      cells: [
        DataCell(
          Text(
            rota.nomeEntregador,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Text(
            rota.ativa ? "Ativa" : "Inativa",
            style: TextStyle(
              color: rota.ativa ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(Text("${rota.paradas.length} paradas")),
        DataCell(
          SizedBox(
            width: 250,
            child: Text(
              resumoTrajeto.isEmpty ? "Sem paradas" : resumoTrajeto,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                onPressed: () => onEdit(rota),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => onDelete(rota),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => rotas.length;
  @override
  int get selectedRowCount => 0;
}
