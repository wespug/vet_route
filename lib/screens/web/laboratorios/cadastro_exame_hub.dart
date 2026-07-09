import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controllers/exame_controller.dart';
import '../../../models/laboratorio_model.dart';
import '../../../models/exame_model.dart';

class CadastroExameHub extends StatefulWidget {
  final Laboratorio labContexto;

  const CadastroExameHub({super.key, required this.labContexto});

  @override
  State<CadastroExameHub> createState() => _CadastroExameHubState();
}

class _CadastroExameHubState extends State<CadastroExameHub> {
  final ExameController _controller = ExameController();

  final List<String> _especies = [
    'Canino',
    'Felino',
    'Equino',
    'Bovino',
    'Silvestre',
    'Outros',
  ];
  final List<String> _portes = ['Pequeno', 'Médio', 'Grande', 'Todos'];

  @override
  void initState() {
    super.initState();
    _controller.carregarExames(widget.labContexto.id ?? '');
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
          // 💡 CABEÇALHO PADRÃO DO DESIGN SYSTEM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Catálogo de Exames 🔬",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gerencie os exames oferecidos pela base de ${widget.labContexto.nome}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCaixaExame(context),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  "Novo Exame",
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

          // 💡 LISTAGEM NA TABELA CORPORATIVA
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  );
                }

                return ValueListenableBuilder<List<ExameModel>>(
                  valueListenable: _controller.exames,
                  builder: (context, exames, _) {
                    if (exames.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Nenhum exame catalogado neste laboratório.",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade50,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Nome do Exame',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Espécie',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Porte',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Orientações/Detalhes',
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
                          rows: exames.map((exame) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    exame.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      exame.especie,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(exame.porte)),
                                DataCell(
                                  SizedBox(
                                    width: 250,
                                    child: Text(
                                      exame.detalhes,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          color: Colors.blue,
                                        ),
                                        tooltip: "Editar Exame",
                                        onPressed: () => _abrirModalCaixaExame(
                                          context,
                                          exameAtual: exame,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: "Excluir Exame",
                                        onPressed: () =>
                                            _confirmarExclusaoExame(
                                              context,
                                              exame,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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

  // 💡 MODAL UNIFICADO (CADASTRO E EDIÇÃO)
  void _abrirModalCaixaExame(BuildContext context, {ExameModel? exameAtual}) {
    final bool isEdicao = exameAtual != null;

    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: exameAtual?.nome ?? '');
    final detalhesController = TextEditingController(
      text: exameAtual?.detalhes ?? '',
    );

    String especieSelecionada = exameAtual?.especie ?? 'Canino';
    String porteSelecionado = exameAtual?.porte ?? 'Todos';

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
                    isEdicao ? Icons.edit_note_rounded : Icons.science_rounded,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Exame" : "Cadastrar Novo Exame"),
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
                          controller: nomeController,
                          decoration: const InputDecoration(
                            labelText: "Nome do Exame",
                            prefixIcon: Icon(Icons.biotech_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Campo obrigatório"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: especieSelecionada,
                                decoration: const InputDecoration(
                                  labelText: "Espécie Alvo",
                                  prefixIcon: Icon(Icons.pets_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                items: _especies
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setModalState(
                                  () => especieSelecionada = val!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: porteSelecionado,
                                decoration: const InputDecoration(
                                  labelText: "Porte do Animal",
                                  prefixIcon: Icon(
                                    Icons.monitor_weight_outlined,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                items: _portes
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setModalState(
                                  () => porteSelecionado = val!,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: detalhesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Detalhes e Orientações de Coleta",
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.assignment_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Campo obrigatório"
                              : null,
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
                              // Edição direta no banco mantendo o MVC fluído
                              await FirebaseFirestore.instance
                                  .collection('exames')
                                  .doc(exameAtual.id)
                                  .update({
                                    'nome': nomeController.text.trim(),
                                    'detalhes': detalhesController.text.trim(),
                                    'especie': especieSelecionada,
                                    'porte': porteSelecionado,
                                  });
                              await _controller.carregarExames(
                                widget.labContexto.id!,
                              );
                            } else {
                              // Adição através da Controladora existente
                              await _controller.salvarExame(
                                laboratorioId: widget.labContexto.id!,
                                nome: nomeController.text.trim(),
                                detalhes: detalhesController.text.trim(),
                                porte: porteSelecionado,
                                especie: especieSelecionada,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdicao
                                        ? "Exame atualizado com sucesso!"
                                        : "Exame cadastrado com sucesso!",
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
                        : (isEdicao ? "Atualizar Exame" : "Cadastrar Exame"),
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

  // 💡 DIÁLOGO DE EXCLUSÃO
  void _confirmarExclusaoExame(BuildContext context, ExameModel exame) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Excluir Exame?"),
            ],
          ),
          content: Text(
            "Tem certeza de que deseja excluir o exame '${exame.nome}'? Ele deixará de ser oferecido por este laboratório.",
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
                _controller.removerExame(exame.id!, widget.labContexto.id!);
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
