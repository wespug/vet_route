import 'package:flutter/material.dart';
import 'package:vet_route/controllers/perfil_controller.dart';
import 'package:vet_route/controllers/menu_controller.dart' as custom_menu;
import 'package:vet_route/controllers/submenu_controller.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';

class GestaoPerfisHub extends StatefulWidget {
  const GestaoPerfisHub({super.key});

  @override
  State<GestaoPerfisHub> createState() => _GestaoPerfisHubState();
}

class _GestaoPerfisHubState extends State<GestaoPerfisHub> {
  final PerfilController _perfilController = PerfilController();
  final custom_menu.MenuController _menuController =
      custom_menu.MenuController();
  final SubmenuController _submenuController = SubmenuController();

  @override
  void initState() {
    super.initState();
    _perfilController.carregarPerfis();
    _menuController.carregarMenus();
    _submenuController.carregarSubmenus();
  }

  @override
  void dispose() {
    _perfilController.dispose();
    _menuController.dispose();
    _submenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _perfilController,
        _menuController,
        _submenuController,
      ]),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Gestão de Perfis & Permissões",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Crie perfis e defina plataformas e menus permitidos para cada cargo.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _perfilController.carregando
                        ? null
                        : () => _abrirMatrizDePermissoes(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.security_rounded),
                    label: const Text(
                      "Novo Perfil de Acesso",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // TABELA DE EXIBIÇÃO
              Expanded(
                child: _perfilController.carregando
                    ? const Center(child: CircularProgressIndicator())
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

  Widget _buildTabelaPerfis() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          dataRowHeight: 65,
          columns: const [
            DataColumn(
              label: Text(
                'Nome do Perfil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Plataformas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ), // 💡 Nova Coluna
            ),
            DataColumn(
              label: Text(
                'Acessos',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      perfil.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  // 💡 Visualização rápida de onde o perfil acessa
                  Row(
                    children: [
                      if (perfil.visivelWeb)
                        const Icon(
                          Icons.laptop_mac_rounded,
                          size: 20,
                          color: Colors.blue,
                        ),
                      if (perfil.visivelWeb && perfil.visivelApp)
                        const SizedBox(width: 8),
                      if (perfil.visivelApp)
                        const Icon(
                          Icons.smartphone_rounded,
                          size: 20,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    "${perfil.menusAcesso.length} Menus | ${perfil.submenusAcesso.length} Submenus",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: Colors.blue,
                        ),
                        tooltip: "Editar Permissões",
                        onPressed: () => _abrirMatrizDePermissoes(
                          context,
                          perfilEdicao: perfil,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: "Excluir Perfil",
                        onPressed: () =>
                            _confirmarExclusao(perfil.id, perfil.nome),
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

  Widget _buildGradeVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Ainda não existem perfis configurados.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _abrirMatrizDePermissoes(
    BuildContext context, {
    PerfilAcesso? perfilEdicao,
  }) {
    final nomeController = TextEditingController(
      text: perfilEdicao?.nome ?? '',
    );

    // 💡 Controle Local para Plataformas no Modal
    bool isWebChecked = perfilEdicao?.visivelWeb ?? true;
    bool isAppChecked = perfilEdicao?.visivelApp ?? false;

    final Set<String> menusSelecionados = Set.from(
      perfilEdicao?.menusAcesso ?? [],
    );
    final Set<String> submenusSelecionados = Set.from(
      perfilEdicao?.submenusAcesso ?? [],
    );

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
                    Icons.admin_panel_settings_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    perfilEdicao == null
                        ? "Novo Perfil"
                        : "Editar - ${perfilEdicao.nome}",
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: "Nome do Cargo / Perfil",
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 💡 SELETORES DE PLATAFORMA MESTRA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Login Permitido em:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilterChip(
                            label: const Text("Painel Web"),
                            avatar: const Icon(
                              Icons.laptop_mac_rounded,
                              size: 16,
                            ),
                            selected: isWebChecked,
                            onSelected: (val) =>
                                setModalState(() => isWebChecked = val),
                            selectedColor: Colors.blue.shade100,
                            checkmarkColor: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          FilterChip(
                            label: const Text("App Mobile"),
                            avatar: const Icon(
                              Icons.smartphone_rounded,
                              size: 16,
                            ),
                            selected: isAppChecked,
                            onSelected: (val) =>
                                setModalState(() => isAppChecked = val),
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "Módulos Permitidos (Telas):",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _menuController.menus.isEmpty
                          ? const Center(
                              child: Text("Nenhum menu base registado."),
                            )
                          : ListView.builder(
                              itemCount: _menuController.menus.length,
                              itemBuilder: (context, index) {
                                final menu = _menuController.menus[index];
                                final bool isMenuSelecionado = menusSelecionados
                                    .contains(menu.id);
                                final submenusDoMenu = _submenuController
                                    .submenus
                                    .where((s) => s.menuId == menu.id)
                                    .toList();

                                return ExpansionTile(
                                  initiallyExpanded: isMenuSelecionado,
                                  leading: Checkbox(
                                    value: isMenuSelecionado,
                                    onChanged: (bool? checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          menusSelecionados.add(menu.id);
                                        } else {
                                          menusSelecionados.remove(menu.id);
                                          for (var sub in submenusDoMenu) {
                                            submenusSelecionados.remove(sub.id);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  title: Text(
                                    menu.titulo,
                                    style: TextStyle(
                                      fontWeight: isMenuSelecionado
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  children: submenusDoMenu.map((submenu) {
                                    final bool isSubmenuSelecionado =
                                        submenusSelecionados.contains(
                                          submenu.id,
                                        );
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 48.0,
                                      ),
                                      child: CheckboxListTile(
                                        title: Text(
                                          submenu.titulo,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        value: isSubmenuSelecionado,
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        onChanged: (bool? checked) {
                                          setModalState(() {
                                            if (checked == true) {
                                              submenusSelecionados.add(
                                                submenu.id,
                                              );
                                              menusSelecionados.add(menu.id);
                                            } else {
                                              submenusSelecionados.remove(
                                                submenu.id,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text(
                    "Salvar Perfil",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (nomeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("O nome é obrigatório."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (!isWebChecked && !isAppChecked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Marque ao menos uma Plataforma de Login.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    if (perfilEdicao == null) {
                      await _perfilController.adicionarPerfil(
                        nomeController.text.trim(),
                        menusSelecionados.toList(),
                        submenusSelecionados.toList(),
                        isWebChecked, // 💡 Passando os booleanos!
                        isAppChecked, // 💡 Passando os booleanos!
                      );
                    } else {
                      await _perfilController.editarPerfil(
                        perfilEdicao.id,
                        nomeController.text.trim(),
                        menusSelecionados.toList(),
                        submenusSelecionados.toList(),
                        isWebChecked, // 💡 Passando os booleanos!
                        isAppChecked, // 💡 Passando os booleanos!
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

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
          content: Text("Deseja eliminar o perfil '$nome'?"),
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
                await _perfilController.excluirPerfil(id);
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
