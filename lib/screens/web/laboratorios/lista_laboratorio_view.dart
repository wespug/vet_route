import 'package:flutter/material.dart';
import 'package:vet_route/controllers/laboratorio_admin_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/endereco_model.dart';

class ListaLaboratoriosView extends StatefulWidget {
  final ValueChanged<Laboratorio>
  onLabSelected; // 💡 GATILHO DA NOVA UX MESTRE-DETALHE

  const ListaLaboratoriosView({super.key, required this.onLabSelected});

  @override
  State<ListaLaboratoriosView> createState() => _ListaLaboratoriosViewState();
}

class _ListaLaboratoriosViewState extends State<ListaLaboratoriosView> {
  final LaboratorioAdminController _controller = LaboratorioAdminController();

  // 🔎 VARIÁVEIS DE BUSCA, ORDENAÇÃO E PAGINAÇÃO LIMPA
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _controller.ouvirLaboratorios();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // 💡 Proteção principal contra RenderFlex (Tela Vermelha)
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Força o layout compacto
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
                  onPressed: () => _abrirModalFormulario(context),
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

            // 🔎 CAMPO DE BUSCA
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por Nome, CNPJ ou Cidade...',
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
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0; // Reseta a página ao buscar
                });
              },
            ),
            const SizedBox(height: 24),

            // 💡 LISTAGEM COMPACTA E INTELIGENTE
            ValueListenableBuilder<List<Laboratorio>>(
              valueListenable: _controller.laboratorios,
              builder: (context, todosLaboratorios, child) {
                // 1. APLICAR BUSCA
                List<Laboratorio> filtrados = todosLaboratorios.where((lab) {
                  if (_searchQuery.isEmpty) return true;
                  final termo = _searchQuery.toLowerCase();
                  return lab.nome.toLowerCase().contains(termo) ||
                      lab.cnpj.toLowerCase().contains(termo) ||
                      lab.endereco.cidade.toLowerCase().contains(termo);
                }).toList();

                // 2. APLICAR ORDENAÇÃO
                filtrados.sort((a, b) {
                  int result = 0;
                  switch (_sortColumnIndex) {
                    case 0:
                      result = a.nome.toLowerCase().compareTo(
                        b.nome.toLowerCase(),
                      );
                      break;
                    case 1:
                      result = a.cnpj.compareTo(b.cnpj);
                      break;
                    case 2:
                      result = a.endereco.cidade.toLowerCase().compareTo(
                        b.endereco.cidade.toLowerCase(),
                      );
                      break;
                    default:
                      result = a.nome.compareTo(b.nome);
                  }
                  return _isAscending ? result : -result;
                });

                // Tratamento de lista vazia
                if (filtrados.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
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
                            _searchQuery.isNotEmpty
                                ? "Nenhum laboratório encontrado para '$_searchQuery'."
                                : "Nenhum laboratório cadastrado ainda.",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 3. APLICAR PAGINAÇÃO MANUAL E COMPACTA
                int totalItems = filtrados.length;
                int totalPages = (totalItems / _itemsPerPage).ceil();
                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }

                int startIndex = _currentPage * _itemsPerPage;
                int endIndex = startIndex + _itemsPerPage;
                if (endIndex > totalItems) endIndex = totalItems;

                List<Laboratorio> paginados = filtrados.sublist(
                  startIndex,
                  endIndex,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min, // Força layout compacto
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _isAscending,
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade50,
                          ),
                          columns: [
                            DataColumn(
                              label: const Text(
                                'Laboratório',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (col, asc) => setState(() {
                                _sortColumnIndex = col;
                                _isAscending = asc;
                              }),
                            ),
                            const DataColumn(
                              label: Text(
                                'CNPJ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: const Text(
                                'Localização',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (col, asc) => setState(() {
                                _sortColumnIndex = col;
                                _isAscending = asc;
                              }),
                            ),
                            const DataColumn(
                              label: Text(
                                'Ações',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: paginados
                              .map((lab) => _buildRowReal(lab))
                              .toList(),
                        ),
                      ),
                    ),

                    // Controles de Paginação
                    if (totalPages > 1) const SizedBox(height: 12),
                    if (totalPages > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Página ${_currentPage + 1} de $totalPages",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  color: _currentPage > 0
                                      ? Colors.indigo
                                      : Colors.grey.shade300,
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.grey.shade300,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  color: _currentPage < totalPages - 1
                                      ? Colors.indigo
                                      : Colors.grey.shade300,
                                  onPressed: _currentPage < totalPages - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRowReal(Laboratorio lab) {
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => widget.onLabSelected(
              lab,
            ), // Clicou no nome? Entra no laboratório!
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lab.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    lab.email,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(Text(lab.cnpj)),
        DataCell(Text("${lab.endereco.cidade} - ${lab.endereco.estado}")),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.indigo,
                ),
                tooltip: "Gerenciar Operação",
                onPressed: () => widget.onLabSelected(lab),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                tooltip: "Editar Cadastro",
                onPressed: () => _abrirModalFormulario(context, labEdicao: lab),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: "Remover Laboratório",
                onPressed: () => _confirmarExclusao(lab),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _abrirModalFormulario(BuildContext context, {Laboratorio? labEdicao}) {
    final bool isEdicao = labEdicao != null;

    final nomeController = TextEditingController(text: labEdicao?.nome ?? '');
    final cnpjController = TextEditingController(text: labEdicao?.cnpj ?? '');
    final emailController = TextEditingController(text: labEdicao?.email ?? '');
    final telefoneController = TextEditingController(
      text: labEdicao?.telefone ?? '',
    );

    final cepController = TextEditingController(
      text: labEdicao?.endereco.cep ?? '',
    );
    final ruaController = TextEditingController(
      text: labEdicao?.endereco.logradouro ?? '',
    );
    final numeroController = TextEditingController(
      text: labEdicao?.endereco.numero ?? '',
    );
    final cidadeController = TextEditingController(
      text: labEdicao?.endereco.cidade ?? '',
    );
    final estadoController = TextEditingController(
      text: labEdicao?.endereco.estado ?? '',
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
                    isEdicao ? Icons.edit_note_rounded : Icons.science_rounded,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Laboratório" : "Novo Laboratório"),
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
                            bairro: labEdicao?.endereco.bairro ?? '',
                            cidade: cidadeController.text.trim(),
                            estado: estadoController.text.trim().toUpperCase(),
                          );

                          final labDados = Laboratorio(
                            id: labEdicao?.id,
                            nome: nomeController.text.trim(),
                            email: emailController.text.trim(),
                            telefone: telefoneController.text.trim(),
                            cnpj: cnpjController.text.trim(),
                            endereco: enderecoInstancia,
                          );

                          bool sucesso = false;
                          if (isEdicao) {
                            sucesso = await _controller.atualizarLaboratorio(
                              labEdicao.id!,
                              labDados,
                            );
                          } else {
                            sucesso = await _controller.salvarLaboratorio(
                              labDados,
                            );
                          }

                          if (sucesso && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdicao
                                      ? "Dados atualizados!"
                                      : "Laboratório vinculado!",
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

  void _confirmarExclusao(Laboratorio lab) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Remover Vínculo?"),
            ],
          ),
          content: Text(
            "Tem certeza de que deseja excluir o laboratório '${lab.nome}'?",
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
                if (lab.id != null) {
                  await _controller.deletarLaboratorio(lab.id!);
                }
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
