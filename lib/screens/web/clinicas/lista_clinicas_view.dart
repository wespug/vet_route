import 'package:flutter/material.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/endereco_model.dart';
import 'package:vet_route/controllers/clinica_controller.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';

class ListaClinicasView extends StatefulWidget {
  final ValueChanged<Clinica> onClinicaSelected;

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
              const Text(
                "Clínicas Parceiras 🏥",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalFormulario(context),
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
          const SizedBox(height: 24),

          Expanded(
            child: ValueListenableBuilder<List<Clinica>>(
              valueListenable: _clinicaController.todasClinicas,
              builder: (context, listaClinicas, child) {
                if (listaClinicas.isEmpty) {
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
                          "Nenhuma clínica cadastrada ainda.",
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
                            'Clínica',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'CNPJ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Localização',
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
                      rows: listaClinicas
                          .map((clinica) => _buildRowReal(clinica))
                          .toList(),
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

  DataRow _buildRowReal(Clinica clinica) {
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => widget.onClinicaSelected(clinica),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    clinica.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    clinica.email,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(Text(clinica.cnpj.isNotEmpty ? clinica.cnpj : 'N/A')),
        DataCell(
          Text("${clinica.endereco.cidade} - ${clinica.endereco.estado}"),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.teal),
                tooltip: "Acessar Painel",
                onPressed: () => widget.onClinicaSelected(clinica),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                tooltip: "Editar Cadastro",
                onPressed: () =>
                    _abrirModalFormulario(context, clinicaEdicao: clinica),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: "Remover Clínica",
                onPressed: () => _confirmarExclusao(clinica),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _abrirModalFormulario(BuildContext context, {Clinica? clinicaEdicao}) {
    final bool isEdicao = clinicaEdicao != null;

    final nomeController = TextEditingController(
      text: clinicaEdicao?.nome ?? '',
    );
    final cnpjController = TextEditingController(
      text: clinicaEdicao?.cnpj ?? '',
    );
    final emailController = TextEditingController(
      text: clinicaEdicao?.email ?? '',
    );
    final telefoneController = TextEditingController(
      text: clinicaEdicao?.telefone ?? '',
    );

    final cepController = TextEditingController(
      text: clinicaEdicao?.endereco.cep ?? '',
    );
    final ruaController = TextEditingController(
      text: clinicaEdicao?.endereco.logradouro ?? '',
    );
    final numeroController = TextEditingController(
      text: clinicaEdicao?.endereco.numero ?? '',
    );
    final cidadeController = TextEditingController(
      text: clinicaEdicao?.endereco.cidade ?? '',
    );
    final estadoController = TextEditingController(
      text: clinicaEdicao?.endereco.estado ?? '',
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
                        : Icons.local_hospital_rounded,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Clínica" : "Nova Clínica Parceira"),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dados Principais",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nomeController,
                              decoration: const InputDecoration(
                                labelText: "Razão Social / Nome",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: cnpjController,
                              decoration: const InputDecoration(
                                labelText: "CNPJ",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: "E-mail de Contato",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: telefoneController,
                              decoration: const InputDecoration(
                                labelText: "Telefone",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(
                          "Localização",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cepController,
                              decoration: const InputDecoration(
                                labelText: "CEP",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: cidadeController,
                              decoration: const InputDecoration(
                                labelText: "Cidade",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: estadoController,
                              maxLength: 2,
                              decoration: const InputDecoration(
                                labelText: "Estado (UF)",
                                counterText: "",
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: ruaController,
                              decoration: const InputDecoration(
                                labelText: "Rua / Avenida",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: numeroController,
                              decoration: const InputDecoration(
                                labelText: "Número",
                              ),
                            ),
                          ),
                        ],
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
                          if (nomeController.text.isEmpty ||
                              cnpjController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Preencha Nome e CNPJ."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final enderecoInstancia = Endereco(
                            cep: cepController.text.trim(),
                            logradouro: ruaController.text.trim(),
                            numero: numeroController.text.trim(),
                            bairro: clinicaEdicao?.endereco.bairro ?? '',
                            cidade: cidadeController.text.trim(),
                            estado: estadoController.text.trim().toUpperCase(),
                          );

                          final clinicaDados = Clinica(
                            id: clinicaEdicao?.id,
                            nome: nomeController.text.trim(),
                            email: emailController.text.trim(),
                            telefone: telefoneController.text.trim(),
                            cnpj: cnpjController.text.trim(),
                            endereco: enderecoInstancia,
                          );

                          bool sucesso = false;
                          if (isEdicao && clinicaEdicao?.id != null) {
                            sucesso = await _clinicaController.atualizarClinica(
                              clinicaEdicao!.id!,
                              clinicaDados,
                            );
                          } else {
                            sucesso = await _clinicaController.salvarClinica(
                              clinicaDados,
                            );
                          }

                          if (sucesso && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdicao
                                      ? "Dados atualizados!"
                                      : "Clínica vinculada!",
                                ),
                                backgroundColor: Colors.green,
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
                      : Icon(
                          isEdicao
                              ? Icons.check_circle_outline
                              : Icons.save_rounded,
                          size: 18,
                        ),
                  label: Text(
                    isLoading
                        ? "Processando..."
                        : (isEdicao ? "Atualizar" : "Salvar"),
                  ),
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
              ),
              onPressed: () async {
                Navigator.pop(context);
                if (clinica.id != null) {
                  await _clinicaController.deletarClinica(clinica.id!);
                }
              },
              child: const Text(
                "Excluir Definitivamente",
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
