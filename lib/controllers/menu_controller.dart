import 'package:flutter/material.dart';
import 'package:vet_route/models/menu_item_model.dart';
import 'package:vet_route/repositories/menu_repository.dart';

class MenuController extends ChangeNotifier {
  final MenuRepository _repository = MenuRepository();

  List<MenuItemModel> _menus = [];
  List<MenuItemModel> get menus => _menus;

  bool _carregando = false;
  bool get carregando => _carregando;

  Future<void> carregarMenus() async {
    _carregando = true;
    notifyListeners();
    try {
      _menus = await _repository.buscarMenus();
    } catch (e) {
      debugPrint("Erro na controller de menus: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // 💡 NOVO: Recebe as plataformas
  Future<void> adicionarMenu(
    String titulo,
    String icone,
    String rota,
    bool isWeb,
    bool isMobile,
  ) async {
    if (titulo.isEmpty || rota.isEmpty) return;

    final novoMenu = MenuItemModel(
      id: '',
      titulo: titulo,
      icone: icone,
      rota: rota,
      isWeb: isWeb,
      isMobile: isMobile,
    );
    await _repository.salvarMenu(novoMenu);
    await carregarMenus();
  }

  // 💡 NOVO: Recebe as plataformas
  Future<void> editarMenu(
    String id,
    String titulo,
    String icone,
    String rota,
    bool isWeb,
    bool isMobile,
  ) async {
    if (titulo.isEmpty || rota.isEmpty) return;

    final menuModificado = MenuItemModel(
      id: id,
      titulo: titulo,
      icone: icone,
      rota: rota,
      isWeb: isWeb,
      isMobile: isMobile,
    );
    await _repository.atualizarMenu(id, menuModificado);
    await carregarMenus();
  }

  Future<void> excluirMenu(String menuId) async {
    await _repository.deletarMenu(menuId);
    await carregarMenus();
  }
}
