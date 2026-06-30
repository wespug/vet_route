import 'package:flutter/material.dart';
import 'package:vet_route/controllers/menu_controller.dart' as custom;
import 'package:vet_route/models/menu_item_model.dart';

class GestaoMenusHub extends StatefulWidget {
  const GestaoMenusHub({Key? key}) : super(key: key);

  @override
  State<GestaoMenusHub> createState() => _GestaoMenusHubState();
}

class _GestaoMenusHubState extends State<GestaoMenusHub> {
  final custom.MenuController _menuController = custom.MenuController();
  final TextEditingController _tituloController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 💡 Estados de controle para o Modo de Edição
  String? _menuEdicaoId;
  String _iconeSelecionado = 'local_hospital';
  String _paginaSelecionada = 'clinica_gestao';

  final Map<String, IconData> _iconesMapeados = {
    'local_hospital': Icons.local_hospital,
    'science': Icons.science,
    'motorcycle': Icons.motorcycle,
    'admin_panel_settings': Icons.admin_panel_settings,
    'layers': Icons.layers,
    'account_tree': Icons.account_tree,
    'people': Icons.people,
    'dashboard': Icons.dashboard,
  };

  final Map<String, String> _paginasMapeadas = {
    'clinica_gestao': 'Gestão de Clínicas',
    'lista_laboratorios': 'Gestão de Laboratórios',
    'entregador_gestao': 'Gestão de Entregadores',
    'gestao_perfis': 'Gestão de Perfis',
    'gestao_menus': 'Gestão de Menus',
    'gestao_submenus': 'Gestão de Submenus',
    'gestao_usuarios': 'Gestão de Usuários',
  };

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

  // Ativa a premonição do formulário superior colocando os dados em modo de edição
  void _entrarModoEdicao(MenuItemModel menu) {
    setState(() {
      _menuEdicaoId = menu.id;
      _tituloController.text = menu.titulo;
      // Garante fallbacks caso haja lixo de dados antigos no Firebase
      _iconeSelecionado = _iconesMapeados.containsKey(menu.icone)
          ? menu.icone
          : 'local_hospital';
      _paginaSelecionada = _paginasMapeadas.containsKey(menu.rota)
          ? menu.rota
          : 'clinica_gestao';
    });
  }

  void _limparFormulario() {
    setState(() {
      _menuEdicaoId = null;
      _tituloController.clear();
      _iconeSelecionado = 'local_hospital';
      _paginaSelecionada = 'clinica_gestao';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditando = _menuEdicaoId != null;

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
              Text(
                isEditando
                    ? "A modificar as configurações do menu ativo..."
                    : "Defina dinamicamente o nome, ícone e ecrã de destino de cada item de navegação.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // PAINEL DE OPERAÇÃO DINÂMICO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isEditando
                      ? Colors.blue.shade50.withOpacity(0.4)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEditando
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _tituloController,
                          decoration: InputDecoration(
                            labelText: "Nome do Menu",
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
                              ? "Insira o nome"
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _iconeSelecionado,
                          decoration: InputDecoration(
                            labelText: "Ícone Visual",
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _iconesMapeados.keys
                              .map(
                                (key) => DropdownMenuItem(
                                  value: key,
                                  child: Row(
                                    children: [
                                      Icon(_iconesMapeados[key], size: 18),
                                      const SizedBox(width: 8),
                                      Text(key),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(
                            () => _iconeSelecionado = val ?? 'local_hospital',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _paginaSelecionada,
                          decoration: InputDecoration(
                            labelText: "Ecrã de Destino",
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _paginasMapeadas.keys
                              .map(
                                (key) => DropdownMenuItem(
                                  value: key,
                                  child: Text(_paginasMapeadas[key]!),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(
                            () => _paginaSelecionada = val ?? 'clinica_gestao',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // BOTÃO REATIVO: ADICIONAR OU ATUALIZAR
                      ElevatedButton.icon(
                        onPressed: _menuController.carregando
                            ? null
                            : _processarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditando
                              ? Colors.blue.shade700
                              : Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          isEditando
                              ? Icons.save_as_rounded
                              : Icons.playlist_add_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          isEditando ? "Guardar Alterações" : "Adicionar",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      if (isEditando) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _limparFormulario,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // LISTAGEM DE DADOS
              Expanded(
                child: _menuController.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _menuController.menus.isEmpty
                    ? const Center(child: Text("Nenhum menu registado."))
                    : _buildTabelaMenus(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processarFormulario() async {
    if (_formKey.currentState!.validate()) {
      final titulo = _tituloController.text.trim();

      if (_menuEdicaoId == null) {
        // Fluxo de Inserção Padrão
        await _menuController.adicionarMenu(
          titulo,
          _iconeSelecionado,
          _paginaSelecionada,
        );
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Menu registado com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        // Fluxo de Edição Persistente
        await _menuController.editarMenu(
          _menuEdicaoId!,
          titulo,
          _iconeSelecionado,
          _paginaSelecionada,
        );
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Configurações do menu atualizadas!"),
              backgroundColor: Colors.blue,
            ),
          );
      }

      _limparFormulario();
    }
  }

  Widget _buildTabelaMenus() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'Ícone',
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
                'Ecrã Alvo',
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
                  Icon(
                    _iconesMapeados[menu.icone] ?? Icons.widgets,
                    color: Colors.indigo,
                  ),
                ),
                DataCell(
                  Text(
                    menu.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    _paginasMapeadas[menu.rota] ?? menu.rota,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.blue,
                        ),
                        tooltip: "Modificar Item",
                        onPressed: () =>
                            _entrarModoEdicao(menu), // Ativa a edição inline
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: "Remover Item",
                        onPressed: () =>
                            _confirmarExclusao(menu.id, menu.titulo),
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
            "Deseja realmente eliminar o menu '$titulo'? Os ecrãs dependentes deixarão de carregar.",
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
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Menu removido."),
                      backgroundColor: Colors.orange,
                    ),
                  );
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
