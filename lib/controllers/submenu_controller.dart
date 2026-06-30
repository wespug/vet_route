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
      debugPrint("Erro submenus: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // 💡 AGORA SIM: Recebe os 6 parâmetros corretamente!
  Future<void> adicionarSubmenu(
    String menuId,
    String titulo,
    String icone,
    String rota,
    bool isWeb,
    bool isMobile,
  ) async {
    if (menuId.isEmpty || titulo.isEmpty || rota.isEmpty) return;

    final novoSubmenu = SubmenuItemModel(
      id: '',
      menuId: menuId,
      titulo: titulo,
      icone: icone,
      rota: rota,
      isWeb: isWeb,
      isMobile: isMobile,
    );

    await _repository.salvarSubmenu(novoSubmenu);
    await carregarSubmenus();
  }

  // 💡 AGORA SIM: A função editarSubmenu existe!
  Future<void> editarSubmenu(
    String id,
    String menuId,
    String titulo,
    String icone,
    String rota,
    bool isWeb,
    bool isMobile,
  ) async {
    if (menuId.isEmpty || titulo.isEmpty || rota.isEmpty) return;

    final submenuAtualizado = SubmenuItemModel(
      id: id,
      menuId: menuId,
      titulo: titulo,
      icone: icone,
      rota: rota,
      isWeb: isWeb,
      isMobile: isMobile,
    );

    await _repository.atualizarSubmenu(id, submenuAtualizado);
    await carregarSubmenus();
  }

  Future<void> excluirSubmenu(String submenuId) async {
    await _repository.deletarSubmenu(submenuId);
    await carregarSubmenus();
  }
}
