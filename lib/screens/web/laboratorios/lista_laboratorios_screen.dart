import 'package:flutter/material.dart';
import 'package:vet_route/controllers/laboratorio_admin_controller.dart'; // Ajuste o import se necessário
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/endereco_model.dart'; // Import da classe endereço que você citou

class ListaLaboratoriosView extends StatefulWidget {
  const ListaLaboratoriosView({super.key});

  @override
  State<ListaLaboratoriosView> createState() => _ListaLaboratoriosViewState();
}

class _ListaLaboratoriosViewState extends State<ListaLaboratoriosView> {
  // Instancia a SUA controladora sênior!
  final LaboratorioAdminController _controller = LaboratorioAdminController();

  @override
  void initState() {
    super.initState();
    // Inicia a escuta reativa em tempo real com o Firestore!
    _controller.ouvirLaboratorios();
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
              const Text(
                "Laboratórios Parceiros 🔬",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCadastro(context),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text(
                  "Vincular Novo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 💡 ValueListenableBuilder PARA OUVIR APENAS A LISTA DA SUA CONTROLADORA
          Expanded(
            child: ValueListenableBuilder<List<Laboratorio>>(
              valueListenable: _controller.laboratorios,
              builder: (context, listaLabs, child) {
                if (listaLabs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.biotech_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhum laboratório cadastrado ainda.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // A TABELA REAL
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
                            'Laboratório',
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
                      rows: listaLabs.map((lab) => _buildRowReal(lab)).toList(),
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

  // 💡 Transformando o SEU LaboratorioModel em uma Linha Visual da Tabela
  DataRow _buildRowReal(Laboratorio lab) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lab.nome,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Text(
                lab.email,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        DataCell(Text(lab.cnpj)),
        // Lendo os dados de dentro da sua classe aninhada 'Endereco'
        DataCell(Text("${lab.endereco.cidade} - ${lab.endereco.estado}")),
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            tooltip: "Remover Laboratório",
            onPressed: () {
              if (lab.id != null) {
                _controller.deletarLaboratorio(lab.id!);
              }
            },
          ),
        ),
      ],
    );
  }

  // 💡 O MODAL DE CADASTRO USANDO O SEU MODELO COMPLEXO
  void _abrirModalCadastro(BuildContext context) {
    final nomeController = TextEditingController();
    final cnpjController = TextEditingController();
    final emailController = TextEditingController();
    final telefoneController = TextEditingController();

    // Campos do Endereço
    final cepController = TextEditingController();
    final ruaController = TextEditingController();
    final numeroController = TextEditingController();
    final cidadeController = TextEditingController();
    final estadoController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // ValueListenableBuilder para ouvir o loading do SEU controller
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoading,
          builder: (context, isLoading, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.science_rounded, color: Colors.indigo),
                  SizedBox(width: 10),
                  Text("Novo Laboratório"),
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
                          color: Colors.indigo,
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
                            color: Colors.indigo,
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
                              decoration: const InputDecoration(
                                labelText: "Estado (UF)",
                                maxLength: 2,
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

                          // Constrói o Endereco
                          final novoEndereco = Endereco(
                            cep: cepController.text.trim(),
                            rua: ruaController.text.trim(),
                            numero: numeroController.text.trim(),
                            bairro: '', // Pode adicionar depois
                            cidade: cidadeController.text.trim(),
                            estado: estadoController.text.trim().toUpperCase(),
                            latitude: 0.0, // Mock pro mapa depois
                            longitude: 0.0, // Mock pro mapa depois
                          );

                          // Constrói o Laboratório
                          final novoLab = Laboratorio(
                            nome: nomeController.text.trim(),
                            email: emailController.text.trim(),
                            telefone: telefoneController.text.trim(),
                            cnpj: cnpjController.text.trim(),
                            endereco: novoEndereco,
                          );

                          // Usa o SEU método de salvamento
                          final sucesso = await _controller.salvarLaboratorio(
                            novoLab,
                          );

                          if (sucesso && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Laboratório cadastrado com sucesso!",
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
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isLoading ? "Salvando..." : "Salvar Laboratório"),
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
}
