import 'package:flutter/material.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/controllers/clinica_controller.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';

class ListaClinicasView extends StatefulWidget {
  final Function(Clinica) onClinicaSelected;

  const ListaClinicasView({super.key, required this.onClinicaSelected});

  @override
  State<ListaClinicasView> createState() => _ListaClinicasViewState();
}

class _ListaClinicasViewState extends State<ListaClinicasView> {
  late final ClinicaController _clinicaController;

  @override
  void initState() {
    super.initState();
    _clinicaController = ClinicaController(FirestoreColetaRepository());
    _clinicaController.carregarClinicas();
  }

  @override
  void dispose() {
    _clinicaController.dispose();
    super.dispose();
  }

  void _abrirModalCadastro({Clinica? clinicaEdicao}) {
    final bool isEdicao = clinicaEdicao != null;
    final formKey = GlobalKey<FormState>();

    final nomeController = TextEditingController(
      text: clinicaEdicao?.nome ?? '',
    );
    final emailController = TextEditingController(
      text: clinicaEdicao?.email ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: _clinicaController.isLoading,
          builder: (context, isLoading, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isEdicao
                        ? Icons.edit_note_rounded
                        : Icons.add_business_rounded,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Clínica" : "Nova Clínica Parceira"),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: "Nome da Clínica",
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? "Campo obrigatório"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "E-mail de Contato",
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? "Campo obrigatório"
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          try {
                            if (isEdicao) {
                              await _clinicaController.editarClinica(
                                clinicaEdicao
                                    .id!, // 💡 GARANTIA DE NÃO-NULO AQUI
                                nomeController.text.trim(),
                                emailController.text.trim(),
                              );
                            } else {
                              await _clinicaController.adicionarClinica(
                                nomeController.text.trim(),
                                emailController.text.trim(),
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Clínica salva com sucesso!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erro: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isLoading ? "Salvando..." : "Salvar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

  void _confirmarExclusao(Clinica clinica) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Apagar Clínica?"),
            ],
          ),
          content: Text(
            "Deseja eliminar definitivamente a clínica '${clinica.nome}' e todos os seus vínculos?",
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
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _clinicaController.excluirClinica(
                    clinica.id!,
                  ); // 💡 GARANTIA DE NÃO-NULO AQUI
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Clínica removida com sucesso."),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erro: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              child: const Text(
                "Excluir Definitivamente",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
                    "Gestão de Clínicas 🏥",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gerencie as clínicas parceiras e acesse seus painéis individuais.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCadastro(),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text(
                  "Nova Clínica",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _clinicaController.todasClinicas,
                _clinicaController.isLoading,
              ]),
              builder: (context, child) {
                if (_clinicaController.isLoading.value &&
                    _clinicaController.todasClinicas.value.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }

                if (_clinicaController.todasClinicas.value.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.domain_disabled_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhuma clínica cadastrada no banco de dados.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
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
                            'Nome da Clínica',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'E-mail de Contato',
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
                      rows: _clinicaController.todasClinicas.value.map((
                        clinica,
                      ) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                clinica.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            DataCell(Text(clinica.email)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.login_rounded,
                                      size: 16,
                                    ),
                                    label: const Text("Acessar Painel"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade50,
                                      foregroundColor: Colors.teal.shade700,
                                      elevation: 0,
                                    ),
                                    onPressed: () =>
                                        widget.onClinicaSelected(clinica),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_note_rounded,
                                      color: Colors.blue,
                                    ),
                                    tooltip: "Editar Cadastro",
                                    onPressed: () => _abrirModalCadastro(
                                      clinicaEdicao: clinica,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: "Excluir Clínica",
                                    onPressed: () =>
                                        _confirmarExclusao(clinica),
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
            ),
          ),
        ],
      ),
    );
  }
}
