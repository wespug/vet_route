import 'package:flutter/material.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class ModalNovoChamado extends StatefulWidget {
  final bool isEmergencia;
  final ChamadoColetaController controller;
  final Clinica clinicaContexto;

  const ModalNovoChamado({
    super.key,
    required this.isEmergencia,
    required this.controller,
    required this.clinicaContexto,
  });

  @override
  State<ModalNovoChamado> createState() => _ModalNovoChamadoState();
}

class _ModalNovoChamadoState extends State<ModalNovoChamado> {
  String? _labIdSelecionado;
  String? _labNomeSelecionado;
  DateTime dataSelecionada = DateTime.now();
  final TextEditingController observacaoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final strData =
        "${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(
            widget.isEmergencia
                ? Icons.flash_on_rounded
                : Icons.calendar_today_rounded,
            color: widget.isEmergencia ? Colors.redAccent : Colors.indigo,
          ),
          const SizedBox(width: 10),
          Text(
            widget.isEmergencia
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
                valueListenable: widget.controller.laboratorios,
                builder: (context, laboratorios, child) {
                  if (laboratorios.isEmpty)
                    return const Text(
                      "⚠️ Nenhum laboratório cadastrado.",
                      style: TextStyle(color: Colors.redAccent),
                    );
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
                      setState(() {
                        _labIdSelecionado = val;
                        if (val != null) {
                          final labSelecionado = laboratorios.firstWhere(
                            (l) => l['id'] == val,
                          );
                          _labNomeSelecionado =
                              labSelecionado['nome'] as String;
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
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
                    setState(() => dataSelecionada = pickedDate);
                },
                child: Container(
                  width: double.infinity,
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
                      Text(strData, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        "Após o agendamento, o laboratório irá confirmar o horário disponível.",
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
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEmergencia
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
              isEmergencia: widget.isEmergencia,
              dataCriacao: DateTime.now(),
              dataAgendamento: momentoAgendado,
            );

            final sucesso = await widget.controller.criarChamado(chamado);

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
  }
}
