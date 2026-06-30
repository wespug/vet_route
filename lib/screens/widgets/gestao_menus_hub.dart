import 'package:flutter/material.dart';
import 'package:vet_route/controllers/menu_controller.dart' as custom;
import 'package:vet_route/models/menu_item_model.dart';

class GestaoMenusHub extends StatefulWidget {
  const GestaoMenusHub({super.key});

  @override
  State<GestaoMenusHub> createState() => _GestaoMenusHubState();
}

class _GestaoMenusHubState extends State<GestaoMenusHub> {
  final custom.MenuController _menuController = custom.MenuController();
  final TextEditingController _tituloController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _menuController.carregarMenus();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _menuController,
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
                "Gestão de Menus do Sistema",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // 💡 CORREÇÃO 1: Removido o 'const' inicial e corrigida a sintaxe da cor
              Text(
                "Cadastre e remova os módulos de navegação da plataforma de forma simplificada.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // PAINEL DE CRIAÇÃO INLINE SIMPLIFICADO
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
                    // 💡 CORREÇÃO 2: Alterado de Center (Widget) para CrossAxisAlignment.center (Enum)
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _tituloController,
                          decoration: InputDecoration(
                            labelText: "Nome do Menu",
                            hintText: "Ex: Faturamento, Triagem, Estoque...",
                            prefixIcon: const Icon(
                              Icons.label_important_outline_rounded,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? "Insira o nome do menu"
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: _menuController.carregando
                              ? null
                              : _submeterNovoMenu,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.playlist_add_rounded),
                          label: const Text(
                            "Adicionar",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TABELA DE EXIBIÇÃO SIMPLIFICADA
              Expanded(
                child: _menuController.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _menuController.menus.isEmpty
                    ? _buildGradeVazia()
                    : _buildTabelaMenus(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submeterNovoMenu() async {
    if (_formKey.currentState!.validate()) {
      final titulo = _tituloController.text.trim();

      await _menuController.adicionarMenu(titulo);
      _tituloController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Menu registrado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildTabelaMenus() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          dataRowHeight: 60,
          columns: const [
            DataColumn(
              label: Text(
                'ID no Banco',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Nome do Módulo',
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
          rows: _menuController.menus.map((menu) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    menu.id,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    menu.titulo,
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
                    onPressed: () => _confirmarExclusao(menu.id, menu.titulo),
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
          Icon(
            Icons.layers_clear_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Nenhum menu cadastrado na base de dados.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(String id, String titulo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Remover Menu?"),
            ],
          ),
          content: Text(
            "Deseja realmente remover o menu '$titulo'? Ele deixará de ser renderizado na barra de acessos.",
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
                Navigator.pop(context);
                await _menuController.excluirMenu(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Menu removido do sistema."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text(
                "Remover",
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
