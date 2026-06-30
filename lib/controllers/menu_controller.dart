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

  Future<void> adicionarMenu(String titulo) async {
    if (titulo.isEmpty) return;

    final novoMenu = MenuItemModel(id: '', titulo: titulo);
    await _repository.salvarMenu(novoMenu);
    await carregarMenus();
  }

  Future<void> excluirMenu(String menuId) async {
    await _repository.deletarMenu(menuId);
    await carregarMenus();
  }
}
