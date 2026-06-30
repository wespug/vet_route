import 'package:flutter/material.dart';
import 'package:vet_route/models/submenu_item_model.dart';
import 'package:vet_route/repositories/submenu_repository.dart';

class SubmenuController extends ChangeNotifier {
  final SubmenuRepository _repository = SubmenuRepository();

  List<SubmenuItemModel> _submenus = [];
  List<SubmenuItemModel> get submenus => _submenus;

  bool _carregando = false;
  bool get carregando => _carregando;

  Future<void> carregarSubmenus() async {
    _carregando = true;
    notifyListeners();

    try {
      _submenus = await _repository.buscarSubmenus();
    } catch (e) {
      debugPrint("Erro na controller de submenus: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> adicionarSubmenu(String menuId, String titulo) async {
    if (menuId.isEmpty || titulo.isEmpty) return;

    final novoSubmenu = SubmenuItemModel(
      id: '',
      menuId: menuId,
      titulo: titulo,
    );
    await _repository.salvarSubmenu(novoSubmenu);
    await carregarSubmenus();
  }

  Future<void> excluirSubmenu(String submenuId) async {
    await _repository.deletarSubmenu(submenuId);
    await carregarSubmenus();
  }
}
