import 'package:flutter/material.dart';
import '../../../controllers/rota_controller.dart';
import '../../../models/laboratorio_model.dart';
import '../../../models/rota_model.dart';

class GestaoRotasHub extends StatefulWidget {
  final Laboratorio labContexto;

  const GestaoRotasHub({super.key, required this.labContexto});

  @override
  State<GestaoRotasHub> createState() => _GestaoRotasHubState();
}

class _GestaoRotasHubState extends State<GestaoRotasHub> {
  final RotaController _controller = RotaController();

  // 🔎 VARIÁVEIS DE BUSCA, PAGINAÇÃO E ORDENAÇÃO
  String _termoBusca = '';
  int _linhasPorPagina = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _controller.carregarRotas(widget.labContexto.id ?? '');
    _controller.inicializarDadosFormulario(); // Carrega os Dropdowns
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
                    "Roteirização Logística 🗺️",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mapeie rotas fixas de coleta para os motoboys da base ${widget.labContexto.nome}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCaixaRota(context),
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
              hintText: 'Buscar por nome do motoboy...',
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

                return ValueListenableBuilder<List<RotaModel>>(
                  valueListenable: _controller.rotas,
                  builder: (context, rotas, _) {
                    // 1. APLICA FILTRO DE BUSCA
                    List<RotaModel> rotasFiltradas = rotas.where((r) {
                      return r.nomeEntregador.toLowerCase().contains(
                        _termoBusca.toLowerCase(),
                      );
                    }).toList();

                    // 2. APLICA ORDENAÇÃO (CLIQUE NO CABEÇALHO)
                    rotasFiltradas.sort((a, b) {
                      int result = 0;
                      switch (_sortColumnIndex) {
                        case 0: // Nome do Motoboy
                          result = a.nomeEntregador.toLowerCase().compareTo(
                            b.nomeEntregador.toLowerCase(),
                          );
                          break;
                        case 1: // Status (Ativa/Inativa)
                          int valA = a.ativa ? 1 : 0;
                          int valB = b.ativa ? 1 : 0;
                          result = valA.compareTo(valB);
                          break;
                        case 2: // Qtd Paradas
                          result = a.paradas.length.compareTo(b.paradas.length);
                          break;
                      }
                      return _isAscending ? result : -result;
                    });

                    if (rotasFiltradas.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _termoBusca.isNotEmpty
                                  ? "Nenhuma rota encontrada para '$_termoBusca'."
                                  : "Nenhuma rota fixa cadastrada.",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final dataSource = _RotasDataSource(
                      context: context,
                      rotas: rotasFiltradas,
                      onEdit: (rota) =>
                          _abrirModalCaixaRota(context, rotaAtual: rota),
                      onDelete: (rota) => _confirmarExclusaoRota(context, rota),
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
                                'Motoboy Designado',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) {
                                setState(() {
                                  _sortColumnIndex = colIndex;
                                  _isAscending = asc;
                                });
                              },
                            ),
                            DataColumn(
                              label: const Text(
                                'Status da Rota',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) {
                                setState(() {
                                  _sortColumnIndex = colIndex;
                                  _isAscending = asc;
                                });
                              },
                            ),
                            DataColumn(
                              label: const Text(
                                'Qtd. Paradas',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (colIndex, asc) {
                                setState(() {
                                  _sortColumnIndex = colIndex;
                                  _isAscending = asc;
                                });
                              },
                            ),
                            const DataColumn(
                              label: Text(
                                'Resumo do Trajeto',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  void _abrirModalCaixaRota(BuildContext context, {RotaModel? rotaAtual}) {
    final bool isEdicao = rotaAtual != null;
    final formKey = GlobalKey<FormState>();

    String? entregadorIdSelecionado = rotaAtual?.entregadorId;
    String nomeEntregadorSelecionado = rotaAtual?.nomeEntregador ?? '';
    bool rotaAtiva = rotaAtual?.ativa ?? true;

    // Lista temporária de paradas para o modal
    List<ParadaRota> paradasTemporarias = isEdicao
        ? List.from(rotaAtual.paradas)
        : [];

    // Controllers para adicionar nova parada
    String? clinicaIdNovaParada;
    String nomeClinicaNovaParada = '';
    final horarioController = TextEditingController();

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
                    isEdicao ? Icons.route : Icons.add_road_rounded,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Rota Fixa" : "Planejar Nova Rota"),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SEÇÃO 1: DADOS DA ROTA
                        const Text(
                          "1. Motoboy Responsável",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),

                        ValueListenableBuilder<List<Map<String, dynamic>>>(
                          valueListenable: _controller.entregadoresDisponiveis,
                          builder: (context, entregadores, _) {
                            final bool isVazio = entregadores.isEmpty;

                            return DropdownButtonFormField<String>(
                              value: isVazio ? null : entregadorIdSelecionado,
                              decoration: InputDecoration(
                                labelText: isVazio
                                    ? "⚠️ Nenhum Motoboy cadastrado no banco"
                                    : "Selecione o Entregador",
                                prefixIcon: const Icon(
                                  Icons.sports_motorsports,
                                ),
                                border: const OutlineInputBorder(),
                                filled: isVazio,
                                fillColor: isVazio ? Colors.red.shade50 : null,
                              ),
                              items: isVazio
                                  ? null
                                  : entregadores
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e['id'] as String,
                                            child: Text(e['nome'] as String),
                                          ),
                                        )
                                        .toList(),
                              onChanged: isVazio
                                  ? null
                                  : (val) {
                                      setModalState(() {
                                        entregadorIdSelecionado = val;
                                        nomeEntregadorSelecionado =
                                            entregadores.firstWhere(
                                                  (e) => e['id'] == val,
                                                )['nome']
                                                as String;
                                      });
                                    },
                              validator: (v) => isVazio
                                  ? "Cadastre um motoboy primeiro"
                                  : (v == null ? "Obrigatório" : null),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            "Status da Rota",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            rotaAtiva
                                ? "A rota aparecerá no aplicativo do motoboy"
                                : "A rota ficará suspensa",
                          ),
                          value: rotaAtiva,
                          activeColor: Colors.green,
                          onChanged: (val) =>
                              setModalState(() => rotaAtiva = val),
                        ),

                        const Divider(height: 32),

                        // SEÇÃO 2: MONTAR O TRAJETO
                        const Text(
                          "2. Montar Trajeto (Adicionar Paradas)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child:
                                    ValueListenableBuilder<
                                      List<Map<String, dynamic>>
                                    >(
                                      valueListenable:
                                          _controller.clinicasDisponiveis,
                                      builder: (context, clinicas, _) {
                                        final bool isVazio = clinicas.isEmpty;

                                        return DropdownButtonFormField<String>(
                                          value: isVazio
                                              ? null
                                              : clinicaIdNovaParada,
                                          decoration: InputDecoration(
                                            labelText: isVazio
                                                ? "⚠️ Nenhuma clínica cadastrada"
                                                : "Selecionar Clínica",
                                            prefixIcon: const Icon(
                                              Icons.local_hospital,
                                            ),
                                            border: const OutlineInputBorder(),
                                            filled: isVazio,
                                            fillColor: isVazio
                                                ? Colors.red.shade50
                                                : null,
                                          ),
                                          items: isVazio
                                              ? null
                                              : clinicas
                                                    .map(
                                                      (c) => DropdownMenuItem(
                                                        value:
                                                            c['id'] as String,
                                                        child: Text(
                                                          c['nome'] as String,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                          onChanged: isVazio
                                              ? null
                                              : (val) {
                                                  setModalState(() {
                                                    clinicaIdNovaParada = val;
                                                    nomeClinicaNovaParada =
                                                        clinicas.firstWhere(
                                                              (c) =>
                                                                  c['id'] ==
                                                                  val,
                                                            )['nome']
                                                            as String;
                                                  });
                                                },
                                        );
                                      },
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: horarioController,
                                  decoration: const InputDecoration(
                                    labelText: "Horário (ex: 14:30)",
                                    prefixIcon: Icon(Icons.access_time),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (entregadorIdSelecionado == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Selecione o Motoboy primeiro!",
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    if (clinicaIdNovaParada != null &&
                                        horarioController.text.isNotEmpty) {
                                      final novoHorario = horarioController.text
                                          .trim();

                                      bool conflitoInterno = paradasTemporarias
                                          .any(
                                            (p) =>
                                                p.horarioPrevisto ==
                                                novoHorario,
                                          );
                                      if (conflitoInterno) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "⚠️ O motoboy já tem uma parada marcada às $novoHorario nesta mesma rota!",
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      bool conflitoExterno = false;
                                      String nomeClinicaConflito = '';

                                      for (var rotaExistente
                                          in _controller.rotas.value) {
                                        if (rotaExistente.entregadorId ==
                                                entregadorIdSelecionado &&
                                            rotaExistente.id != rotaAtual?.id) {
                                          for (var parada
                                              in rotaExistente.paradas) {
                                            if (parada.horarioPrevisto ==
                                                novoHorario) {
                                              conflitoExterno = true;
                                              nomeClinicaConflito =
                                                  parada.nomeClinica;
                                              break;
                                            }
                                          }
                                        }
                                        if (conflitoExterno) break;
                                      }

                                      if (conflitoExterno) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "⚠️ Conflito! Este motoboy já visita a clínica '$nomeClinicaConflito' às $novoHorario em outra rota!",
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      setModalState(() {
                                        paradasTemporarias.add(
                                          ParadaRota(
                                            clinicaId: clinicaIdNovaParada!,
                                            nomeClinica: nomeClinicaNovaParada,
                                            horarioPrevisto: novoHorario,
                                          ),
                                        );
                                        clinicaIdNovaParada = null;
                                        nomeClinicaNovaParada = '';
                                        horarioController.clear();
                                      });
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Preencha a Clínica e o Horário!",
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SEÇÃO 3: TIMELINE DA ROTA
                        if (paradasTemporarias.isNotEmpty) ...[
                          const Text(
                            "Trajeto Desenhado:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: paradasTemporarias.length,
                            itemBuilder: (context, index) {
                              final parada = paradasTemporarias[index];
                              return Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.shade50,
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(
                                        color: Colors.indigo.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    parada.nomeClinica,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Passar às: ${parada.horarioPrevisto}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => setModalState(
                                      () => paradasTemporarias.removeAt(index),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        if (paradasTemporarias.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                "Nenhuma clínica adicionada à rota ainda.",
                                style: TextStyle(color: Colors.red.shade300),
                              ),
                            ),
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
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (paradasTemporarias.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "A rota precisa de pelo menos uma clínica!",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setModalState(() => salvando = true);

                          try {
                            final rotaSalvar = RotaModel(
                              id: rotaAtual?.id,
                              laboratorioId: widget.labContexto.id!,
                              entregadorId: entregadorIdSelecionado!,
                              nomeEntregador: nomeEntregadorSelecionado,
                              paradas: paradasTemporarias,
                              ativa: rotaAtiva,
                            );

                            await _controller.salvarRota(rotaSalvar);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Rota salva com sucesso!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erro: $e"),
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
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(salvando ? "Salvando..." : "Salvar Rota"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarExclusaoRota(BuildContext context, RotaModel rota) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Excluir Rota?"),
            ],
          ),
          content: Text(
            "Tem certeza de que deseja excluir a rota do motoboy '${rota.nomeEntregador}'?",
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
                _controller.removerRota(rota.id!, widget.labContexto.id!);
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
class _RotasDataSource extends DataTableSource {
  final BuildContext context;
  final List<RotaModel> rotas;
  final Function(RotaModel) onEdit;
  final Function(RotaModel) onDelete;

  _RotasDataSource({
    required this.context,
    required this.rotas,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= rotas.length) return null;
    final rota = rotas[index];

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              const Icon(
                Icons.sports_motorsports_rounded,
                color: Colors.indigo,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                rota.nomeEntregador,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rota.ativa ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rota.ativa ? "Ativa" : "Inativa",
              style: TextStyle(
                fontSize: 12,
                color: rota.ativa ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            "${rota.paradas.length} paradas",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          SizedBox(
            width: 250,
            child: Text(
              rota.paradas.map((p) => p.nomeClinica).join(" ➔ "),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                tooltip: "Editar Rota",
                onPressed: () => onEdit(rota),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: "Excluir Rota",
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
