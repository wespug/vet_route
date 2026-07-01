import 'package:flutter/material.dart';
import 'package:vet_route/models/menu_item_model.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';
import 'package:vet_route/models/submenu_item_model.dart';
import 'package:vet_route/repositories/menu_repository.dart';
import 'package:vet_route/repositories/perfil_repository.dart';
import 'package:vet_route/repositories/submenu_repository.dart';

// 💡 Instância global (Singleton)
final PermissoesController permissoesGlobais = PermissoesController();

class PermissoesController extends ChangeNotifier {
  final PerfilRepository _perfilRepo = PerfilRepository();
  final MenuRepository _menuRepo = MenuRepository();
  final SubmenuRepository _submenuRepo = SubmenuRepository();

  bool _carregando = false;
  bool get carregando => _carregando;

  List<MenuItemModel> _todosMenus = [];
  List<SubmenuItemModel> _todosSubmenus = [];
  PerfilAcesso? _perfilAtual;

  List<MenuItemModel> menusPermitidos = [];
  List<SubmenuItemModel> submenusPermitidos = [];

  // 🚀 O HACK SUPREMO: Construtor roda automaticamente ao abrir o app
  PermissoesController() {
    _ativarModoDeus();
  }

  Future<void> _ativarModoDeus() async {
    _carregando = true;
    Future.microtask(() => notifyListeners()); // Avisa a tela com segurança

    try {
      // Puxa tudo do banco
      _todosMenus = await _menuRepo.buscarMenus();
      _todosSubmenus = await _submenuRepo.buscarSubmenus();

      // Libera a catraca geral sem pedir perfil!
      menusPermitidos = _todosMenus;
      submenusPermitidos = _todosSubmenus;
    } catch (e) {
      debugPrint("Erro no Modo Deus: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // 🛡️ O Código Oficial (que usaremos após fechar a gestão de utilizadores)
  Future<void> inicializarParaUsuario(String perfilId) async {
    _carregando = true;
    notifyListeners();

    try {
      _todosMenus = await _menuRepo.buscarMenus();
      _todosSubmenus = await _submenuRepo.buscarSubmenus();
      final todosPerfis = await _perfilRepo.buscarPerfis();

      // Busca o perfil com segurança para não dar crash se o ID for inválido
      try {
        _perfilAtual = todosPerfis.firstWhere((p) => p.id == perfilId);
      } catch (e) {
        _perfilAtual = null;
      }

      _filtrarAcessos();
    } catch (e) {
      debugPrint("Erro ao carregar permissões: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void _filtrarAcessos() {
    if (_perfilAtual == null) {
      menusPermitidos = [];
      submenusPermitidos = [];
      return;
    }

    menusPermitidos = _todosMenus
        .where((menu) => _perfilAtual!.menusAcesso.contains(menu.id))
        .toList();
    submenusPermitidos = _todosSubmenus
        .where((submenu) => _perfilAtual!.submenusAcesso.contains(submenu.id))
        .toList();
  }

  List<SubmenuItemModel> getSubmenusDoMenu(String menuId) {
    return submenusPermitidos.where((sub) => sub.menuId == menuId).toList();
  }
}
