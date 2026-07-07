import 'package:flutter/material.dart';
import 'package:vet_route/models/entregador_model.dart';
import 'package:vet_route/models/endereco_model.dart';
import 'package:vet_route/models/veiculo_model.dart';
import 'package:vet_route/controllers/entregador_controller.dart';

class ListaEntregadoresView extends StatefulWidget {
  final ValueChanged<Entregador> onEntregadorSelected;

  const ListaEntregadoresView({super.key, required this.onEntregadorSelected});

  @override
  State<ListaEntregadoresView> createState() => _ListaEntregadoresViewState();
}

class _ListaEntregadoresViewState extends State<ListaEntregadoresView> {
  late final EntregadorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EntregadorController();
    _controller.carregarEntregadores();
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
                "Entregadores Parceiros 🏍️",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalFormulario(context),
                icon: const Icon(Icons.sports_motorsports_rounded),
                label: const Text(
                  "Novo Motoboy",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ValueListenableBuilder<List<Entregador>>(
              valueListenable: _controller.todosEntregadores,
              builder: (context, lista, child) {
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.two_wheeler_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhum motoboy cadastrado.",
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
                            'Motoboy',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Veículo (Placa)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Localização Base',
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
                      rows: lista.map((ent) => _buildRowReal(ent)).toList(),
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

  DataRow _buildRowReal(Entregador entregador) {
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => widget.onEntregadorSelected(entregador),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entregador.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    entregador.telefone,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            entregador.veiculo != null
                ? "${entregador.veiculo!.modelo} - ${entregador.veiculo!.placa}"
                : 'A definir',
          ),
        ),
        DataCell(
          Text("${entregador.endereco.cidade} - ${entregador.endereco.estado}"),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.deepOrange,
                ),
                tooltip: "Painel do Motoboy",
                onPressed: () => widget.onEntregadorSelected(entregador),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                tooltip: "Editar Cadastro",
                onPressed: () => _abrirModalFormulario(
                  context,
                  entregadorEdicao: entregador,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: "Remover Motoboy",
                onPressed: () => _confirmarExclusao(entregador),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _abrirModalFormulario(
    BuildContext context, {
    Entregador? entregadorEdicao,
  }) {
    final bool isEdicao = entregadorEdicao != null;

    // Controladores do Motoboy
    final nomeController = TextEditingController(
      text: entregadorEdicao?.nome ?? '',
    );
    final emailController = TextEditingController(
      text: entregadorEdicao?.email ?? '',
    );
    final telefoneController = TextEditingController(
      text: entregadorEdicao?.telefone ?? '',
    );

    // Controladores do Veículo
    final placaController = TextEditingController(
      text: entregadorEdicao?.veiculo?.placa ?? '',
    );
    final modeloController = TextEditingController(
      text: entregadorEdicao?.veiculo?.modelo ?? '',
    );
    final corController = TextEditingController(
      text: entregadorEdicao?.veiculo?.cor ?? '',
    );

    // Controladores de Endereço
    final cepController = TextEditingController(
      text: entregadorEdicao?.endereco.cep ?? '',
    );
    final ruaController = TextEditingController(
      text: entregadorEdicao?.endereco.logradouro ?? '',
    );
    final numeroController = TextEditingController(
      text: entregadorEdicao?.endereco.numero ?? '',
    );
    final cidadeController = TextEditingController(
      text: entregadorEdicao?.endereco.cidade ?? '',
    );
    final estadoController = TextEditingController(
      text: entregadorEdicao?.endereco.estado ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoading,
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
                        : Icons.sports_motorsports_rounded,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Motoboy" : "Novo Motoboy"),
                ],
              ),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dados do Entregador",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nomeController,
                              decoration: const InputDecoration(
                                labelText: "Nome Completo",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: telefoneController,
                              decoration: const InputDecoration(
                                labelText: "Telefone / WhatsApp",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "E-mail de Login",
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(
                          "Estrutura do Veículo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: placaController,
                              decoration: const InputDecoration(
                                labelText: "Placa",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: modeloController,
                              decoration: const InputDecoration(
                                labelText: "Modelo (Ex: Honda CG 160)",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: corController,
                              decoration: const InputDecoration(
                                labelText: "Cor",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(
                          "Endereço Base / Residência",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
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
                              emailController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Preencha Nome e E-mail."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final veiculoInstancia =
                              placaController.text.isNotEmpty
                              ? Veiculo(
                                  placa: placaController.text.trim(),
                                  modelo: modeloController.text.trim(),
                                  cor: corController.text.trim(),
                                  tipo: 'Moto', // Padrão MVP
                                )
                              : null;

                          final enderecoInstancia = Endereco(
                            cep: cepController.text.trim(),
                            logradouro: ruaController.text.trim(),
                            numero: numeroController.text.trim(),
                            bairro: entregadorEdicao?.endereco.bairro ?? '',
                            cidade: cidadeController.text.trim(),
                            estado: estadoController.text.trim().toUpperCase(),
                          );

                          final entregadorDados = Entregador(
                            id: entregadorEdicao?.id,
                            nome: nomeController.text.trim(),
                            email: emailController.text.trim(),
                            telefone: telefoneController.text.trim(),
                            veiculo: veiculoInstancia,
                            endereco: enderecoInstancia,
                          );

                          bool sucesso = false;
                          if (isEdicao && entregadorEdicao?.id != null) {
                            sucesso = await _controller.atualizarEntregador(
                              entregadorEdicao!.id!,
                              entregadorDados,
                            );
                          } else {
                            sucesso = await _controller.salvarEntregador(
                              entregadorDados,
                            );
                          }

                          if (sucesso && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdicao
                                      ? "Atualizado!"
                                      : "Motoboy cadastrado!",
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
                    backgroundColor: Colors.deepOrange,
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

  void _confirmarExclusao(Entregador entregador) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Remover Motoboy?"),
            ],
          ),
          content: Text(
            "Tem certeza de que deseja excluir '${entregador.nome}' da base?",
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
                if (entregador.id != null)
                  await _controller.deletarEntregador(entregador.id!);
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
