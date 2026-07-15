import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

import 'package:vet_route/controllers/insumo_controller.dart';
import 'package:vet_route/models/insumo_model.dart';

class GestaoChamadosView extends StatefulWidget {
  final Clinica clinicaContexto;

  const GestaoChamadosView({super.key, required this.clinicaContexto});

  @override
  State<GestaoChamadosView> createState() => _GestaoChamadosViewState();
}

class _GestaoChamadosViewState extends State<GestaoChamadosView>
    with TickerProviderStateMixin {
  final ChamadoColetaController _controller = ChamadoColetaController();

  String? _labIdSelecionado;
  String? _labNomeSelecionado;

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
                onChanged: (value) {
                  setState(() {
                    _termoBusca = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              const TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: "Coletas Ativas & Agendadas"),
                  Tab(text: "Coletas Finalizadas"),
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
              onPressed: () => _abrirModalPedirInsumos(),
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
              onPressed: () => _abrirModalNovoChamado(isEmergencia: false),
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
              onPressed: () => _abrirModalNovoChamado(isEmergencia: true),
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
            List<ChamadoColetaModel> chamadosFiltrados = chamados.where((c) {
              final termo = _termoBusca.toLowerCase();
              final lab = c.laboratorioNome.toLowerCase();
              final status = c.status.toLowerCase();
              return lab.contains(termo) || status.contains(termo);
            }).toList();

            chamadosFiltrados.sort(
              (a, b) => b.dataAgendamento.compareTo(a.dataAgendamento),
            );

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
                                ? "Nenhum histórico de coletas finalizadas."
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

            final dataSource = _ChamadosDataSource(
              context: context,
              chamados: chamadosFiltrados,
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
                        ? "Histórico de Coletas Finalizadas"
                        : "Painel de Coletas Ativas",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  rowsPerPage: _linhasPorPagina,
                  availableRowsPerPage: const [5, 10, 20, 50],
                  onRowsPerPageChanged: (value) {
                    setState(() {
                      _linhasPorPagina =
                          value ?? PaginatedDataTable.defaultRowsPerPage;
                    });
                  },
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
                    ), // Removida a Hora da Tabela
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

  // 💡 MÁGICA REFATORADA: O modal Web agora também salva na coleção pedidos_insumos corretamente
  void _abrirModalPedirInsumos() {
    final InsumoController insumoController = InsumoController();
    bool enviando = false;
    final Map<String, int> quantidadesSelecionadas = {};
    String? localLabIdSelecionado;

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
              title: const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: Colors.teal),
                  SizedBox(width: 10),
                  Text(
                    "Solicitar Insumos ao Laboratório",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Escolha o laboratório parceiro e os materiais desejados.",
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: _controller.laboratorios,
                      builder: (context, laboratorios, child) {
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: laboratorios.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['id'] as String,
                              child: Text(item['nome'] as String),
                            );
                          }).toList(),
                          value: localLabIdSelecionado,
                          hint: const Text("Selecione um laboratório"),
                          onChanged: (val) {
                            setModalState(() {
                              localLabIdSelecionado = val;
                              if (val != null) {
                                quantidadesSelecionadas.clear();
                                insumoController.carregarInsumos(val);
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: localLabIdSelecionado == null
                          ? const Center(
                              child: Text(
                                "Selecione um laboratório para ver os insumos disponíveis.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ValueListenableBuilder<bool>(
                              valueListenable: insumoController.isLoading,
                              builder: (context, isLoading, child) {
                                if (isLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.teal,
                                    ),
                                  );
                                }
                                return ValueListenableBuilder<
                                  List<InsumoModel>
                                >(
                                  valueListenable: insumoController.insumos,
                                  builder: (context, insumos, child) {
                                    if (insumos.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "Nenhum insumo cadastrado neste laboratório.",
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      itemCount: insumos.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(),
                                      itemBuilder: (context, index) {
                                        final insumo = insumos[index];
                                        final qtd =
                                            quantidadesSelecionadas[insumo
                                                .id] ??
                                            0;

                                        return ListTile(
                                          title: Text(
                                            insumo.descricao,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${insumo.tipo} • ${insumo.tamanho} • ${insumo.volume}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: qtd > 0
                                                    ? () => setModalState(
                                                        () =>
                                                            quantidadesSelecionadas[insumo
                                                                    .id!] =
                                                                qtd - 1,
                                                      )
                                                    : null,
                                              ),
                                              Text(
                                                '$qtd',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.teal,
                                                ),
                                                onPressed: () => setModalState(
                                                  () =>
                                                      quantidadesSelecionadas[insumo
                                                              .id!] =
                                                          qtd + 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: enviando
                      ? null
                      : () async {
                          if (localLabIdSelecionado == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Selecione o Laboratório!"),
                              ),
                            );
                            return;
                          }

                          final insumosSelecionados = insumoController
                              .insumos
                              .value
                              .where(
                                (i) =>
                                    (quantidadesSelecionadas[i.id!] ?? 0) > 0,
                              )
                              .map(
                                (i) => {
                                  'insumoId': i.id,
                                  'descricao': i.descricao,
                                  'tipo': i.tipo,
                                  'quantidade': quantidadesSelecionadas[i.id!],
                                },
                              )
                              .toList();

                          if (insumosSelecionados.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Selecione ao menos 1 item!"),
                              ),
                            );
                            return;
                          }

                          setModalState(() => enviando = true);

                          try {
                            // 💡 AGORA SALVA COMO UM PEDIDO ESTRUTURADO NO MUNDO REAL!
                            await FirebaseFirestore.instance
                                .collection('pedidos_insumos')
                                .add({
                                  'clinicaId': widget.clinicaContexto.id,
                                  'clinicaNome': widget.clinicaContexto.nome,
                                  'laboratorioId': localLabIdSelecionado,
                                  'status': 'Pendente',
                                  'dataSolicitacao':
                                      FieldValue.serverTimestamp(),
                                  'itens': insumosSelecionados,
                                });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Pedido de materiais enviado com sucesso!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint("Erro ao salvar pedido WEB: $e");
                            setModalState(() => enviando = false);
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Confirmar Pedido",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => insumoController.dispose());
  }

  // 💡 MUDANÇA PRINCIPAL: Nova Estrutura de Modal (Sem Horário e Com Observação)
  void _abrirModalNovoChamado({required bool isEmergencia}) {
    _labIdSelecionado = null;
    _labNomeSelecionado = null;
    DateTime dataSelecionada = DateTime.now();
    final TextEditingController observacaoController =
        TextEditingController(); // 💡 Novo Controller

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final strData =
                "${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}";

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isEmergencia
                        ? Icons.flash_on_rounded
                        : Icons.calendar_today_rounded,
                    color: isEmergencia ? Colors.redAccent : Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEmergencia
                        ? "Solicitar Coleta de Urgência"
                        : "Agendar Nova Coleta",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "1. Selecione o Laboratório Destino",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _controller.laboratorios,
                        builder: (context, laboratorios, child) {
                          if (laboratorios.isEmpty) {
                            return const Text(
                              "⚠️ Nenhum laboratório cadastrado.",
                              style: TextStyle(color: Colors.redAccent),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: laboratorios.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['id'] as String,
                                child: Text(item['nome'] as String),
                              );
                            }).toList(),
                            value: _labIdSelecionado,
                            hint: const Text("Selecione um laboratório"),
                            onChanged: (val) {
                              setModalState(() {
                                _labIdSelecionado = val;
                                if (val != null) {
                                  final labSelecionado = laboratorios
                                      .firstWhere((l) => l['id'] == val);
                                  _labNomeSelecionado =
                                      labSelecionado['nome'] as String;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // 💡 NOVO: Campo de Observação/Material
                      const Text(
                        "2. Descreva o material a ser coletado",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: observacaoController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              "Ex: 2 tubos de sangue (hemograma), 1 frasco de urina...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 💡 NOVO: Seleção apenas de Data (Sem horário)
                      const Text(
                        "3. Data Desejada para Coleta",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null)
                            setModalState(() => dataSelecionada = pickedDate);
                        },
                        child: Container(
                          width: double.infinity, // Ocupar o espaço inteiro
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.indigo.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                strData,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 💡 NOVO: Mensagem de aviso do laboratório
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Após o agendamento, o laboratório irá confirmar o horário disponível na data solicitada.",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                    backgroundColor: isEmergencia
                        ? Colors.redAccent.shade700
                        : Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_labIdSelecionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Selecione o Laboratório destino!"),
                        ),
                      );
                      return;
                    }

                    // A hora zerada não fará diferença na listagem visual que acabamos de ajustar
                    final momentoAgendado = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      0,
                      0,
                    );

                    final chamado = ChamadoColetaModel(
                      id: '',
                      clinicaId: widget.clinicaContexto.id!,
                      clinicaNome: widget.clinicaContexto.nome,
                      laboratorioId: _labIdSelecionado!,
                      laboratorioNome: _labNomeSelecionado!,
                      status: 'Aguardando Entregador',
                      isEmergencia: isEmergencia,
                      dataCriacao: DateTime.now(),
                      dataAgendamento: momentoAgendado,
                      // observacao: observacaoController.text, // 💡 DESCOMENTE essa linha assim que você adicionar a variável "observacao" no seu arquivo chamado_coleta_model.dart
                    );

                    final sucesso = await _controller.criarChamado(chamado);

                    if (sucesso && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Coleta solicitada com sucesso!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Confirmar Coleta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ChamadosDataSource extends DataTableSource {
  final BuildContext context;
  final List<ChamadoColetaModel> chamados;

  _ChamadosDataSource({required this.context, required this.chamados});

  Color _obterCorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aguardando entregador':
        return Colors.orange;
      case 'a caminho':
        return Colors.blue;
      case 'aguardando insumos':
        return Colors.teal;
      case 'concluído':
      case 'finalizada':
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
    // Hora formatada foi removida da UI!

    final corStatus = _obterCorStatus(chamado.status);

    final bool isInsumo =
        chamado.laboratorioId == 'INSUMOS' ||
        chamado.laboratorioNome.toLowerCase().contains('insumo');

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
        DataCell(Text(dataFormatada)), // 💡 Somente a Data aparece aqui agora!
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: corStatus.withOpacity(0.5)),
            ),
            child: Text(
              chamado.status,
              style: TextStyle(
                color: corStatus,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detalhes em desenvolvimento!')),
              );
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
