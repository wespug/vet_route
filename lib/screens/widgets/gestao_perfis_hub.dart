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
  // Precisamos das 3 controladoras para cruzar os dados na matriz
  final PerfilController _perfilController = PerfilController();
  final custom_menu.MenuController _menuController =
      custom_menu.MenuController();
  final SubmenuController _submenuController = SubmenuController();

  @override
  void initState() {
    super.initState();
    // 💡 Carrega o ecossistema inteiro de acessos
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
                        "Crie perfis e defina a matriz de acesso (Menus e Submenus) para cada cargo.",
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
                'Nº Permissões (Menus)',
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

  // 💡 A MAGIA ACONTECE AQUI: O Modal de Matriz de Permissões
  void _abrirMatrizDePermissoes(
    BuildContext context, {
    PerfilAcesso? perfilEdicao,
  }) {
    final nomeController = TextEditingController(
      text: perfilEdicao?.nome ?? '',
    );

    // Conjuntos para guardar o estado reativo dos checkboxes (Set impede duplicações automáticas)
    final Set<String> menusSelecionados = Set.from(
      perfilEdicao?.menusAcesso ?? [],
    );
    final Set<String> submenusSelecionados = Set.from(
      perfilEdicao?.submenusAcesso ?? [],
    );

    showDialog(
      context: context,
      barrierDismissible: false, // Força a clicar em Cancelar ou Salvar
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
                        ? "Criar Matriz de Permissões"
                        : "Editar Permissões - ${perfilEdicao.nome}",
                  ),
                ],
              ),
              content: SizedBox(
                width: 600, // Matriz mais larga para acomodar a estrutura
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
                    const SizedBox(height: 24),
                    const Text(
                      "Módulos Permitidos:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Estrutura de Árvore (Lista) para Menus e Submenus
                    Container(
                      height: 350,
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

                                // Puxa apenas os submenus deste Menu
                                final submenusDoMenu = _submenuController
                                    .submenus
                                    .where((s) => s.menuId == menu.id)
                                    .toList();

                                return ExpansionTile(
                                  initiallyExpanded:
                                      isMenuSelecionado, // Abre a gaveta se já tiver acesso
                                  leading: Checkbox(
                                    value: isMenuSelecionado,
                                    onChanged: (bool? checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          menusSelecionados.add(menu.id);
                                        } else {
                                          menusSelecionados.remove(menu.id);
                                          // 💡 UX Sênior: Se desmarcar o pai, desmarca todos os filhos
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
                                      ), // Indentação
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
                                              // 💡 UX Sênior: Marcou o filho? Auto-marca o Menu pai para não dar erro de rota
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
                    "Salvar Permissões",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (nomeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("O nome do perfil é obrigatório."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context); // Fecha Modal

                    if (perfilEdicao == null) {
                      // CRIAÇÃO
                      await _perfilController.adicionarPerfil(
                        nomeController.text.trim(),
                        menusSelecionados.toList(),
                        submenusSelecionados.toList(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Matriz de acessos criada com sucesso!",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // EDIÇÃO
                      await _perfilController.editarPerfil(
                        perfilEdicao.id,
                        nomeController.text.trim(),
                        menusSelecionados.toList(),
                        submenusSelecionados.toList(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Permissões atualizadas com sucesso!",
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
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
          content: Text(
            "Tem a certeza de que deseja eliminar o perfil '$nome' do sistema?",
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
                await _perfilController.excluirPerfil(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Perfil eliminado."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
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
