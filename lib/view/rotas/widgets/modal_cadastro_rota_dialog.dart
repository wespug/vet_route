import 'package:flutter/material.dart';
import 'package:vet_route/controllers/rota_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/rota_model.dart';

class ModalCadastroRotaDialog extends StatefulWidget {
  final RotaController controller;
  final Laboratorio labContexto;
  final RotaModel? rotaAtual;

  const ModalCadastroRotaDialog({
    super.key,
    required this.controller,
    required this.labContexto,
    this.rotaAtual,
  });

  @override
  State<ModalCadastroRotaDialog> createState() =>
      _ModalCadastroRotaDialogState();
}

class _ModalCadastroRotaDialogState extends State<ModalCadastroRotaDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _entregadorIdSelecionado;
  String _nomeEntregadorSelecionado = '';
  bool _rotaAtiva = true;

  List<ParadaRota> _paradasTemporarias = [];

  String? _clinicaIdNovaParada;
  String _nomeClinicaNovaParada = '';
  String _turnoSelecionado = 'Manhã';

  final List<String> _diasDaSemana = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];
  List<String> _diasSelecionados = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];

  @override
  void initState() {
    super.initState();
    if (widget.rotaAtual != null) {
      _entregadorIdSelecionado = widget.rotaAtual!.entregadorId;
      _nomeEntregadorSelecionado = widget.rotaAtual!.nomeEntregador;
      _rotaAtiva = widget.rotaAtual!.ativa;
      _paradasTemporarias = List.from(widget.rotaAtual!.paradas);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.rotaAtual != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        width: 650,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEÇÃO 1: MOTOTOBOY & STATUS
                const Text(
                  "1. Motoboy Responsável",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: widget.controller.entregadoresDisponiveis,
                  builder: (context, entregadores, _) {
                    final bool isVazio = entregadores.isEmpty;
                    return DropdownButtonFormField<String>(
                      value: isVazio ? null : _entregadorIdSelecionado,
                      decoration: InputDecoration(
                        labelText: isVazio
                            ? "⚠️ Nenhum Motoboy cadastrado"
                            : "Selecione o Entregador",
                        prefixIcon: const Icon(Icons.sports_motorsports),
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
                              setState(() {
                                _entregadorIdSelecionado = val;
                                _nomeEntregadorSelecionado =
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
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Status da Rota",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _rotaAtiva
                        ? "A rota aparecerá no aplicativo do motoboy"
                        : "A rota ficará suspensa",
                  ),
                  value: _rotaAtiva,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _rotaAtiva = val),
                ),
                const Divider(height: 32),

                // SEÇÃO 2: MONTAR TRAJETO
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child:
                                ValueListenableBuilder<
                                  List<Map<String, dynamic>>
                                >(
                                  valueListenable:
                                      widget.controller.clinicasDisponiveis,
                                  builder: (context, clinicas, _) {
                                    final bool isVazio = clinicas.isEmpty;
                                    return DropdownButtonFormField<String>(
                                      value: isVazio
                                          ? null
                                          : _clinicaIdNovaParada,
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
                                                    value: c['id'] as String,
                                                    child: Text(
                                                      c['nome'] as String,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      onChanged: isVazio
                                          ? null
                                          : (val) {
                                              setState(() {
                                                _clinicaIdNovaParada = val;
                                                _nomeClinicaNovaParada =
                                                    clinicas.firstWhere(
                                                          (c) => c['id'] == val,
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
                            child: DropdownButtonFormField<String>(
                              value: _turnoSelecionado,
                              decoration: const InputDecoration(
                                labelText: "Turno",
                                prefixIcon: Icon(Icons.wb_sunny_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Manhã',
                                  child: Text('Manhã'),
                                ),
                                DropdownMenuItem(
                                  value: 'Tarde',
                                  child: Text('Tarde'),
                                ),
                                DropdownMenuItem(
                                  value: 'Noite',
                                  child: Text('Noite'),
                                ),
                              ],
                              onChanged: (val) => setState(
                                () => _turnoSelecionado = val ?? 'Manhã',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Dias de Coleta:",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _diasDaSemana.map((dia) {
                          final bool estaSelecionado = _diasSelecionados
                              .contains(dia);
                          return FilterChip(
                            label: Text(dia),
                            selected: estaSelecionado,
                            selectedColor: Colors.indigo.shade100,
                            checkmarkColor: Colors.indigo,
                            onSelected: (selected) {
                              setState(() {
                                selected
                                    ? _diasSelecionados.add(dia)
                                    : _diasSelecionados.remove(dia);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final res = widget.controller
                                .adicionarParadaTemporaria(
                                  entregadorId: _entregadorIdSelecionado,
                                  clinicaId: _clinicaIdNovaParada,
                                  nomeClinica: _nomeClinicaNovaParada,
                                  turno: _turnoSelecionado,
                                  diasSelecionados: _diasSelecionados,
                                  paradasAtuais: _paradasTemporarias,
                                );

                            if (!res.sucesso) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.mensagem),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              setState(() {
                                _clinicaIdNovaParada = null;
                                _nomeClinicaNovaParada = '';
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Adicionar Parada"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // SEÇÃO 3: TIMELINE DA ROTA
                if (_paradasTemporarias.isNotEmpty) ...[
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
                    itemCount: _paradasTemporarias.length,
                    itemBuilder: (context, index) {
                      final parada = _paradasTemporarias[index];
                      return Card(
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(parada.horarioPrevisto),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => setState(
                              () => _paradasTemporarias.removeAt(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (_paradasTemporarias.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Adicione pelo menos uma parada na rota!"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final novaRota = RotaModel(
                id: widget.rotaAtual?.id,
                laboratorioId: widget.labContexto.id ?? '',
                entregadorId: _entregadorIdSelecionado!,
                nomeEntregador: _nomeEntregadorSelecionado,
                ativa: _rotaAtiva,
                paradas: _paradasTemporarias,
              );

              final ok = await widget.controller.salvarRota(novaRota);
              if (ok && context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.save_rounded, size: 18),
          label: Text(isEdicao ? "Salvar Alterações" : "Salvar Rota"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
