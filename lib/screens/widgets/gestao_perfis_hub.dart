import 'package:flutter/material.dart';
import 'package:vet_route/controllers/perfil_controller.dart';

class GestaoPerfisHub extends StatefulWidget {
  const GestaoPerfisHub({Key? key}) : super(key: key);

  @override
  State<GestaoPerfisHub> createState() => _GestaoPerfisHubState();
}

class _GestaoPerfisHubState extends State<GestaoPerfisHub> {
  final PerfilController _perfilController = PerfilController();
  final TextEditingController _novoPerfilController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 💡 REQUISITO 2: Assim que a tela abre, busca os perfis reais do banco!
    _perfilController.carregarPerfis();
  }

  @override
  void dispose() {
    _novoPerfilController.dispose();
    _perfilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _perfilController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestão de Perfis de Acesso",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure as funções e cargos disponíveis globalmente no sistema.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // PAINEL DE CRIAÇÃO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _novoPerfilController,
                          decoration: InputDecoration(
                            labelText: "Nome do Novo Perfil / Cargo",
                            prefixIcon: const Icon(
                              Icons.admin_panel_settings_rounded,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return "Introduza um nome válido";
                            if (_perfilController.perfis.any(
                              (p) =>
                                  p.nome.toLowerCase() ==
                                  value.trim().toLowerCase(),
                            )) {
                              return "Este perfil já existe no banco de dados.";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: _perfilController.carregando
                              ? null
                              : _submeterNovoPerfil,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            "Criar Perfil",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TABELA DE DADOS
              Expanded(
                child: _perfilController.carregando
                    ? const Center(
                        child: CircularProgressIndicator(),
                      ) // Mostra loading enquanto busca
                    : _perfilController.perfis.isEmpty
                    ? _buildGradeVazia()
                    : _buildTabelaPerfis(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 💡 REQUISITO 1: Cria o perfil e persiste no Firebase
  void _submeterNovoPerfil() async {
    if (_formKey.currentState!.validate()) {
      final nomePerfil = _novoPerfilController.text.trim();
      await _perfilController.adicionarPerfil(nomePerfil);
      _novoPerfilController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Perfil '$nomePerfil' guardado no banco com sucesso!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildTabelaPerfis() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'ID no Banco',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Nome do Perfil',
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
          rows: _perfilController.perfis.map((perfil) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    perfil.id,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    perfil.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmarExclusao(
                      perfil.id,
                      perfil.nome,
                    ), // Aciona o requisito 3
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGradeVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "O banco de dados está vazio. Crie um perfil acima.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // 💡 REQUISITO 3: Modal de confirmação antes de deletar
  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Apagar Perfil?"),
            ],
          ),
          content: Text(
            "Tem a certeza de que deseja eliminar o perfil '$nome' do banco de dados?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(context); // Fecha o modal
                await _perfilController.excluirPerfil(id); // Deleta no Firebase
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Perfil deletado."),
                      backgroundColor: Colors.orange,
                    ),
                  );
              },
              child: const Text(
                "Eliminar",
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
