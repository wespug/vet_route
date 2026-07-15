import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controllers/insumo_controller.dart';
import '../../../models/laboratorio_model.dart';
import '../../../models/insumo_model.dart';

class CadastroInsumoHub extends StatefulWidget {
  final Laboratorio labContexto;

  const CadastroInsumoHub({super.key, required this.labContexto});

  @override
  State<CadastroInsumoHub> createState() => _CadastroInsumoHubState();
}

class _CadastroInsumoHubState extends State<CadastroInsumoHub> {
  final InsumoController _controller = InsumoController();

  final List<String> _tipos = [
    'Tubo',
    'Swab',
    'Seringa',
    'Agulha',
    'Frasco',
    'Caixa Térmica',
    'Outros',
  ];

  // 🔎 VARIÁVEIS DE BUSCA, PAGINAÇÃO E ORDENAÇÃO
  String _termoBusca = '';
  int _linhasPorPagina = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _controller.carregarInsumos(widget.labContexto.id ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Catálogo de Insumos 📦",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gerencie os materiais fornecidos pela base de ${widget.labContexto.nome}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCaixaInsumo(context),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  "Novo Insumo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🔎 CAMPO DE BUSCA
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar insumo por descrição, tipo ou volume...',
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
                borderSide: const BorderSide(color: Colors.indigo, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _termoBusca = value;
              });
            },
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  );
                }

                return ValueListenableBuilder<List<InsumoModel>>(
                  valueListenable: _controller.insumos,
                  builder: (context, insumos, _) {
                    // 1. APLICA FILTRO DE BUSCA
                    List<InsumoModel> insumosFiltrados = insumos.where((i) {
                      final termo = _termoBusca.toLowerCase();
                      return i.descricao.toLowerCase().contains(termo) ||
                          i.tipo.toLowerCase().contains(termo) ||
                          i.volume.toLowerCase().contains(termo);
                    }).toList();

                    // 2. APLICA ORDENAÇÃO (CLIQUE NO CABEÇALHO)
                    insumosFiltrados.sort((a, b) {
                      int result = 0;
                      switch (_sortColumnIndex) {
                        case 0: // Descrição
                          result = a.descricao.toLowerCase().compareTo(
                            b.descricao.toLowerCase(),
                          );
                          break;
                        case 1: // Categoria
                          result = a.tipo.toLowerCase().compareTo(
                            b.tipo.toLowerCase(),
                          );
                          break;
                        case 2: // Tamanho
                          result = a.tamanho.toLowerCase().compareTo(
                            b.tamanho.toLowerCase(),
                          );
                          break;
                        case 3: // Volume
                          result = a.volume.toLowerCase().compareTo(
                            b.volume.toLowerCase(),
                          );
                          break;
                      }
                      return _isAscending ? result : -result;
                    });

                    if (insumosFiltrados.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _termoBusca.isNotEmpty
                                  ? "Nenhum insumo encontrado para '$_termoBusca'."
                                  : "Nenhum insumo catalogado neste laboratório.",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final dataSource = _InsumosDataSource(
                      context: context,
                      insumos: insumosFiltrados,
                      onEdit: (insumo) =>
                          _abrirModalCaixaInsumo(context, insumoAtual: insumo),
                      onDelete: (insumo) =>
                          _confirmarExclusaoInsumo(context, insumo),
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
                            "Lista de Materiais",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          rowsPerPage: _linhasPorPagina,
                          availableRowsPerPage: const [5, 10, 20, 50],
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _linhasPorPagina =
                                  value ??
                                  PaginatedDataTable.defaultRowsPerPage;
                            });
                          },
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _isAscending,
                          columns: [
                            DataColumn(
                              label: const Text(
                                'Descrição do Item',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) => setState(() {
                                _sortColumnIndex = colIndex;
                                _isAscending = asc;
                              }),
                            ),
                            DataColumn(
                              label: const Text(
                                'Categoria',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) => setState(() {
                                _sortColumnIndex = colIndex;
                                _isAscending = asc;
                              }),
                            ),
                            DataColumn(
                              label: const Text(
                                'Tamanho',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) => setState(() {
                                _sortColumnIndex = colIndex;
                                _isAscending = asc;
                              }),
                            ),
                            DataColumn(
                              label: const Text(
                                'Volume/Qtd',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) => setState(() {
                                _sortColumnIndex = colIndex;
                                _isAscending = asc;
                              }),
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
            ),
          ),
        ],
      ),
    );
  }

  void _abrirModalCaixaInsumo(
    BuildContext context, {
    InsumoModel? insumoAtual,
  }) {
    final bool isEdicao = insumoAtual != null;

    final formKey = GlobalKey<FormState>();
    final descricaoController = TextEditingController(
      text: insumoAtual?.descricao ?? '',
    );
    final tamanhoController = TextEditingController(
      text: insumoAtual?.tamanho ?? '',
    );
    final volumeController = TextEditingController(
      text: insumoAtual?.volume ?? '',
    );

    String tipoSelecionado = insumoAtual?.tipo ?? 'Tubo';
    bool salvando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isEdicao
                        ? Icons.edit_note_rounded
                        : Icons.inventory_2_rounded,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Insumo" : "Cadastrar Novo Insumo"),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Text(
                            "Vínculo Corporativo:\n${widget.labContexto.nome}",
                            style: TextStyle(
                              color: Colors.indigo.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: descricaoController,
                          decoration: const InputDecoration(
                            labelText: "Descrição do Insumo (Ex: Tubo EDTA)",
                            prefixIcon: Icon(Icons.vaccines_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Campo obrigatório"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: tipoSelecionado,
                          decoration: const InputDecoration(
                            labelText: "Categoria / Tipo",
                            prefixIcon: Icon(Icons.category_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: _tipos
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => tipoSelecionado = val!),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: tamanhoController,
                                decoration: const InputDecoration(
                                  labelText: "Tamanho (Ex: 4ml, Pediátrico)",
                                  prefixIcon: Icon(Icons.straighten_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? "Campo obrigatório"
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: volumeController,
                                decoration: const InputDecoration(
                                  labelText:
                                      "Apresentação (Ex: Unidade, Cx c/ 100)",
                                  prefixIcon: Icon(Icons.view_in_ar_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? "Campo obrigatório"
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => salvando = true);

                          try {
                            if (isEdicao) {
                              await FirebaseFirestore.instance
                                  .collection('insumos')
                                  .doc(insumoAtual.id)
                                  .update({
                                    'descricao': descricaoController.text
                                        .trim(),
                                    'tipo': tipoSelecionado,
                                    'tamanho': tamanhoController.text.trim(),
                                    'volume': volumeController.text.trim(),
                                  });
                              await _controller.carregarInsumos(
                                widget.labContexto.id!,
                              );
                            } else {
                              await _controller.salvarInsumo(
                                laboratorioId: widget.labContexto.id!,
                                descricao: descricaoController.text.trim(),
                                tipo: tipoSelecionado,
                                tamanho: tamanhoController.text.trim(),
                                volume: volumeController.text.trim(),
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdicao
                                        ? "Insumo atualizado com sucesso!"
                                        : "Insumo cadastrado com sucesso!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Falha ao salvar: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setModalState(() => salvando = false);
                          }
                        },
                  icon: salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isEdicao
                              ? Icons.check_circle_outline
                              : Icons.add_circle_outline,
                          size: 18,
                        ),
                  label: Text(
                    salvando
                        ? "Salvando..."
                        : (isEdicao ? "Atualizar Insumo" : "Cadastrar Insumo"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarExclusaoInsumo(BuildContext context, InsumoModel insumo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Excluir Insumo?"),
            ],
          ),
          content: Text(
            "Tem certeza de que deseja excluir o insumo '${insumo.descricao}'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(context);
                _controller.removerInsumo(insumo.id!, widget.labContexto.id!);
              },
              child: const Text(
                "Excluir",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 💡 DataSource para a Tabela Paginada
class _InsumosDataSource extends DataTableSource {
  final BuildContext context;
  final List<InsumoModel> insumos;
  final Function(InsumoModel) onEdit;
  final Function(InsumoModel) onDelete;

  _InsumosDataSource({
    required this.context,
    required this.insumos,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= insumos.length) return null;
    final insumo = insumos[index];

    return DataRow(
      cells: [
        DataCell(
          Text(
            insumo.descricao,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              insumo.tipo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text(insumo.tamanho)),
        DataCell(
          Text(insumo.volume, style: TextStyle(color: Colors.grey.shade700)),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                tooltip: "Editar Insumo",
                onPressed: () => onEdit(insumo),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: "Excluir Insumo",
                onPressed: () => onDelete(insumo),
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
  int get rowCount => insumos.length;

  @override
  int get selectedRowCount => 0;
}
