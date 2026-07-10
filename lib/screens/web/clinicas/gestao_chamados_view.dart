import 'package:flutter/material.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class GestaoChamadosView extends StatefulWidget {
  final Clinica clinicaContexto;

  const GestaoChamadosView({super.key, required this.clinicaContexto});

  @override
  State<GestaoChamadosView> createState() => _GestaoChamadosViewState();
}

class _GestaoChamadosViewState extends State<GestaoChamadosView> {
  final ChamadoColetaController _controller = ChamadoColetaController();
  String? _labIdSelecionado;
  String? _labNomeSelecionado;

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
              const TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: "Coletas Ativas & Agendadas"),
                  Tab(text: "Histórico de Dias Anteriores"),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              "Painel logístico da ${widget.clinicaContexto.nome}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _abrirModalNovoChamado(isEmergencia: false),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                "Agendar Coleta",
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
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _abrirModalNovoChamado(isEmergencia: true),
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text(
                "Chamada Emergencial",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            if (chamados.isEmpty) {
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
                      isHistorico
                          ? "Nenhum histórico de coletas passadas."
                          : "Nenhuma coleta ativa ou agendada.",
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

            return ListView.builder(
              itemCount: chamados.length,
              itemBuilder: (context, index) {
                final chamado = chamados[index];

                final String dataFormatada =
                    "${chamado.dataAgendamento.day.toString().padLeft(2, '0')}/${chamado.dataAgendamento.month.toString().padLeft(2, '0')}/${chamado.dataAgendamento.year}";
                final String horaFormatada =
                    "${chamado.dataAgendamento.hour.toString().padLeft(2, '0')}:${chamado.dataAgendamento.minute.toString().padLeft(2, '0')}";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: chamado.isEmergencia
                          ? Colors.red.shade50
                          : Colors.indigo.shade50,
                      child: Icon(
                        chamado.isEmergencia
                            ? Icons.warning_amber_rounded
                            : Icons.local_shipping_outlined,
                        color: chamado.isEmergencia
                            ? Colors.redAccent
                            : Colors.indigo,
                      ),
                    ),
                    title: Text(
                      "Coleta para ${chamado.laboratorioNome}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isHistorico
                          ? "Concluído em: $dataFormatada às $horaFormatada • Status: ${chamado.status}"
                          : "Agendado para: $dataFormatada às $horaFormatada • Status: ${chamado.status}",
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    onTap: () {},
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _abrirModalNovoChamado({required bool isEmergencia}) {
    _labIdSelecionado = null;
    _labNomeSelecionado = null;

    // 💡 Inicializamos o estado com AGORA
    DateTime dataSelecionada = DateTime.now();
    TimeOfDay horaSelecionada = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Strings formatadas para os botões do formulário
            final strData =
                "${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}";
            final strHora = horaSelecionada.format(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isEmergencia
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today_rounded,
                    color: isEmergencia ? Colors.redAccent : Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEmergencia ? "Chamado Emergencial" : "Agendar Coleta",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width:
                    450, // Modal um pouco mais largo para acomodar data e hora lado a lado
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. Selecione o Laboratório Destino",
                      style: TextStyle(
                        color: Colors.grey.shade800,
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

                        final List<DropdownMenuItem<String>> dropDownItems =
                            laboratorios.map((dynamic item) {
                              final l = item as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: l['id'] as String,
                                child: Text(l['nome'] as String),
                              );
                            }).toList();

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: dropDownItems,
                          value: _labIdSelecionado,
                          hint: const Text("Selecione um laboratório"),
                          onChanged: (val) {
                            setModalState(() {
                              _labIdSelecionado = val;
                              if (val != null) {
                                final labSelecionado = laboratorios.firstWhere(
                                  (l) =>
                                      (l as Map<String, dynamic>)['id'] == val,
                                );
                                _labNomeSelecionado =
                                    (labSelecionado
                                            as Map<String, dynamic>)['nome']
                                        as String;
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "2. Data e Horário da Coleta",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 💡 BOTÕES DE SELEÇÃO DE DATA E HORA
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dataSelecionada,
                                firstDate:
                                    DateTime.now(), // Não deixa agendar para o passado
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null &&
                                  pickedDate != dataSelecionada) {
                                setModalState(
                                  () => dataSelecionada = pickedDate,
                                );
                              }
                            },
                            child: Container(
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: horaSelecionada,
                              );
                              if (pickedTime != null &&
                                  pickedTime != horaSelecionada) {
                                setModalState(
                                  () => horaSelecionada = pickedTime,
                                );
                              }
                            },
                            child: Container(
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
                                    Icons.access_time_rounded,
                                    color: Colors.indigo.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    strHora,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        ? Colors.redAccent
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

                    // 💡 Montamos o DateTime definitivo cruzando a Data e a Hora selecionadas
                    final momentoAgendado = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      horaSelecionada.hour,
                      horaSelecionada.minute,
                    );

                    final chamado = ChamadoColetaModel(
                      id: '',
                      clinicaId: widget.clinicaContexto.id!,
                      clinicaNome: widget.clinicaContexto.nome,
                      laboratorioId: _labIdSelecionado!,
                      laboratorioNome: _labNomeSelecionado!,
                      status: 'Aguardando Entregador',
                      isEmergencia: isEmergencia,
                      dataCriacao:
                          DateTime.now(), // Registra a hora que o botão foi clicado (Auditoria)
                      dataAgendamento:
                          momentoAgendado, // A hora real que o motoboy vai buscar
                    );

                    final sucesso = await _controller.criarChamado(chamado);

                    if (sucesso && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Chamado agendado com sucesso!"),
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
