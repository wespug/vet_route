import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';

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

  // 💡 Controle de carregamento no botão para evitar cliques duplos
  bool enviando = false;

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
              ValueListenableBuilder<List<Laboratorio>>(
                valueListenable: widget.controller.laboratorios,
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
                    items: laboratorios.map((lab) {
                      return DropdownMenuItem<String>(
                        value: lab.id,
                        child: Text(
                          lab.nome.isNotEmpty
                              ? lab.nome
                              : 'Laboratório sem nome',
                        ),
                      );
                    }).toList(),
                    value: _labIdSelecionado,
                    hint: const Text("Selecione um laboratório"),
                    onChanged: (val) {
                      setState(() {
                        _labIdSelecionado = val;
                        if (val != null) {
                          final labSelecionado = laboratorios.firstWhere(
                            (l) => l.id == val,
                          );
                          _labNomeSelecionado = labSelecionado.nome;
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
                  if (pickedDate != null) {
                    setState(() => dataSelecionada = pickedDate);
                  }
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
          onPressed: enviando ? null : () => Navigator.pop(context),
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
          onPressed: enviando
              ? null
              : () async {
                  if (_labIdSelecionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecione o Laboratório destino!"),
                      ),
                    );
                    return;
                  }

                  setState(() => enviando = true);

                  try {
                    final momentoAgendado = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      0,
                      0,
                    );

                    // 💡 Pega o usuário logado para carimbar o histórico
                    final user = FirebaseAuth.instance.currentUser;
                    final usuarioLogado = user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : (user?.email ?? 'Usuário da Clínica');

                    // 💡 Gravação Limpa e Perfeita no Banco com Timestamps oficiais
                    await FirebaseFirestore.instance
                        .collection('chamados_coleta')
                        .add({
                          'clinicaId': widget.clinicaContexto.id,
                          'clinicaNome': widget.clinicaContexto.nome,
                          'laboratorioId': _labIdSelecionado,
                          'laboratorioNome':
                              _labNomeSelecionado ?? 'Laboratório',
                          'status': 'Pendente',
                          'isUrgencia': widget.isEmergencia,
                          'isEmergencia': widget.isEmergencia,
                          'dataCriacao':
                              Timestamp.now(), // Formato estrito para não quebrar a tabela
                          'dataAgendamento': Timestamp.fromDate(
                            momentoAgendado,
                          ),
                          'observacao': observacaoController.text,
                          'usuarioCriador': usuarioLogado,
                          'historicoLogs': [
                            {
                              'status': 'Pendente',
                              'usuario': usuarioLogado,
                              'data': Timestamp.now(),
                              'observacao': 'Coleta agendada na plataforma',
                            },
                          ],
                        });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Coleta solicitada com sucesso!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Erro ao salvar coleta WEB: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erro ao agendar coleta: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => enviando = false);
                    }
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
                  "Confirmar Coleta",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
