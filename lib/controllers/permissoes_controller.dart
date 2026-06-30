import 'package:flutter/material.dart';
import 'package:vet_route/models/menu_item_model.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';
import 'package:vet_route/models/submenu_item_model.dart';
import 'package:vet_route/repositories/menu_repository.dart';
import 'package:vet_route/repositories/perfil_repository.dart';
import 'package:vet_route/repositories/submenu_repository.dart';

// 💡 CORREÇÃO CIRÚRGICA: Instância global adicionada no topo do arquivo!
final PermissoesController permissoesGlobais = PermissoesController();

class PermissoesController extends ChangeNotifier {
  final PerfilRepository _perfilRepo = PerfilRepository();
  final MenuRepository _menuRepo = MenuRepository();
  final SubmenuRepository _submenuRepo = SubmenuRepository();

  bool _carregando =
      false; // 💡 Ajustado para inicializar como falso para o Fallback rodar liso
  bool get carregando => _carregando;

  // Listas totais do sistema
  List<MenuItemModel> _todosMenus = [];
  List<SubmenuItemModel> _todosSubmenus = [];

  // O Perfil do usuário logado no momento
  PerfilAcesso? _perfilAtual;

  // As listas filtradas (O "Filtro VIP" que a tela vai usar)
  List<MenuItemModel> menusPermitidos = [];
  List<SubmenuItemModel> submenusPermitidos = [];

  // Método que será chamado assim que o usuário logar
  Future<void> inicializarParaUsuario(String perfilId) async {
    _carregando = true;
    notifyListeners();

    try {
      // 1. Busca todas as listas (Menus e Submenus) do banco
      _todosMenus = await _menuRepo.buscarMenus();
      _todosSubmenus = await _submenuRepo.buscarSubmenus();

      // 2. Busca o perfil completo do usuário (A "Lista VIP")
      final todosPerfis = await _perfilRepo.buscarPerfis();
      _perfilAtual = todosPerfis.firstWhere((p) => p.id == perfilId);

      // 3. Aplica o Filtro VIP!
      _filtrarAcessos();
    } catch (e) {
      debugPrint("Erro ao carregar permissões: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void _filtrarAcessos() {
    if (_perfilAtual == null) return;

    // Filtra os Menus: Só guarda os que o ID estiver na lista menusAcesso do perfil
    menusPermitidos = _todosMenus.where((menu) {
      return _perfilAtual!.menusAcesso.contains(menu.id);
    }).toList();

    // Filtra os Submenus: Só guarda os que o ID estiver na lista submenusAcesso
    submenusPermitidos = _todosSubmenus.where((submenu) {
      return _perfilAtual!.submenusAcesso.contains(submenu.id);
    }).toList();
  }

  // Helper para a Sidebar: Pega só os submenus permitidos de um menu específico
  List<SubmenuItemModel> getSubmenusDoMenu(String menuId) {
    return submenusPermitidos.where((sub) => sub.menuId == menuId).toList();
  }
}
