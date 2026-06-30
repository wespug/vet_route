import 'package:flutter/material.dart';
import 'package:vet_route/controllers/menu_controller.dart' as custom_menu;
import 'package:vet_route/controllers/submenu_controller.dart';
import 'package:vet_route/models/menu_item_model.dart';

class GestaoSubmenusHub extends StatefulWidget {
  const GestaoSubmenusHub({Key? key}) : super(key: key);

  @override
  State<GestaoSubmenusHub> createState() => _GestaoSubmenusHubState();
}

class _GestaoSubmenusHubState extends State<GestaoSubmenusHub> {
  // Instanciamos as duas controladoras para relacionar os dados
  final custom_menu.MenuController _menuController =
      custom_menu.MenuController();
  final SubmenuController _submenuController = SubmenuController();

  final TextEditingController _tituloController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _menuPaiSelecionado;

  @override
  void initState() {
    super.initState();
    // Carrega ambas as coleções em paralelo
    _menuController.carregarMenus();
    _submenuController.carregarSubmenus();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _menuController.dispose();
    _submenuController.dispose();
    super.dispose();
  }

  // Helper para exibir o nome do Menu na tabela em vez do ID
  String _obterNomeMenuPai(String menuId) {
    try {
      return _menuController.menus.firstWhere((m) => m.id == menuId).titulo;
    } catch (e) {
      return 'Menu não encontrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Listenable.merge observa as duas controladoras simultaneamente
    return ListenableBuilder(
      listenable: Listenable.merge([_menuController, _submenuController]),
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
                "Gestão de Submenus",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Crie subníveis de navegação atrelando-os aos Menus principais.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // PAINEL DE CRIAÇÃO INLINE
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _menuPaiSelecionado,
                          decoration: InputDecoration(
                            labelText: "Menu Pai (Destino)",
                            prefixIcon: const Icon(Icons.account_tree_outlined),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _menuController.menus.map((
                            MenuItemModel menu,
                          ) {
                            return DropdownMenuItem<String>(
                              value: menu.id,
                              child: Text(menu.titulo),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _menuPaiSelecionado = val),
                          validator: (v) =>
                              v == null ? "Selecione um Menu Pai" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _tituloController,
                          decoration: InputDecoration(
                            labelText: "Nome do Submenu",
                            hintText: "Ex: Relatório Mensal, Fechamento...",
                            prefixIcon: const Icon(
                              Icons.subdirectory_arrow_right_rounded,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? "Insira o nome do submenu"
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: _submenuController.carregando
                              ? null
                              : _submeterNovoSubmenu,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
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

              // TABELA DE EXIBIÇÃO
              Expanded(
                child:
                    _submenuController.carregando || _menuController.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _submenuController.submenus.isEmpty
                    ? _buildGradeVazia()
                    : _buildTabelaSubmenus(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submeterNovoSubmenu() async {
    if (_formKey.currentState!.validate() && _menuPaiSelecionado != null) {
      final titulo = _tituloController.text.trim();

      await _submenuController.adicionarSubmenu(_menuPaiSelecionado!, titulo);
      _tituloController.clear();
      // Opcional: não limpamos o _menuPaiSelecionado caso o usuário queira adicionar vários no mesmo menu

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Submenu registrado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildTabelaSubmenus() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          dataRowHeight: 60,
          columns: const [
            DataColumn(
              label: Text(
                'Menu Pai',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Nome do Submenu',
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
          rows: _submenuController.submenus.map((submenu) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _obterNomeMenuPai(submenu.menuId),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    submenu.titulo,
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
                    onPressed: () =>
                        _confirmarExclusao(submenu.id, submenu.titulo),
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
            Icons.account_tree_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Nenhum submenu cadastrado na base de dados.",
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
              Text("Remover Submenu?"),
            ],
          ),
          content: Text("Deseja realmente remover o submenu '$titulo'?"),
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
                await _submenuController.excluirSubmenu(id);
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Submenu removido."),
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
