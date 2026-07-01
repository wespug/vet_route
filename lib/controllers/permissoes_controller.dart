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

  PermissoesController();

  // 🛡️ O Código Oficial de Segurança com Super Logs Ativados!
  Future<void> inicializarParaUsuario(String perfilId) async {
    _carregando = true;
    notifyListeners();

    debugPrint("\n=======================================================");
    debugPrint(
      "🔍 [VET ROUTE DETECTOR] A iniciar permissões para Perfil ID: $perfilId",
    );
    debugPrint("=======================================================");

    try {
      // 1. Puxa tudo o que existe no Firestore
      _todosMenus = await _menuRepo.buscarMenus();
      _todosSubmenus = await _submenuRepo.buscarSubmenus();
      final todosPerfis = await _perfilRepo.buscarPerfis();

      debugPrint("📦 Banco de Dados carregado localmente:");
      debugPrint(
        "   -> Total de Menus cadastrados no Firestore: ${_todosMenus.length}",
      );
      for (var m in _todosMenus) {
        debugPrint("      * [Menu ID: ${m.id}] Título: '${m.titulo}'");
      }
      debugPrint(
        "   -> Total de Submenus cadastrados no Firestore: ${_todosSubmenus.length}",
      );
      debugPrint(
        "   -> Total de Perfis cadastrados no Firestore: ${todosPerfis.length}",
      );

      // 2. Tenta encontrar o perfil do utilizador logado
      try {
        _perfilAtual = todosPerfis.firstWhere((p) => p.id == perfilId);
        debugPrint("✅ Perfil Encontrado no Firestore!");
        debugPrint("   -> Nome do Perfil: ${_perfilAtual!.nome}");
        debugPrint(
          "   -> Menus autorizados neste Perfil (IDs no array): ${_perfilAtual!.menusAcesso}",
        );
        debugPrint(
          "   -> Submenus autorizados neste Perfil (IDs no array): ${_perfilAtual!.submenusAcesso}",
        );
      } catch (e) {
        _perfilAtual = null;
        debugPrint(
          "❌ ERRO CRÍTICO: O perfil com ID '$perfilId' NÃO EXISTE na coleção 'perfis' do Firestore!",
        );
      }

      // 3. Executa a filtragem
      _filtrarAcessos();
    } catch (e) {
      debugPrint("💥 Erro geral ao carregar permissões: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void _filtrarAcessos() {
    if (_perfilAtual == null) {
      debugPrint("⚠️ Filtragem Abortada: Nenhum perfil ativo.");
      menusPermitidos = [];
      submenusPermitidos = [];
      return;
    }

    // Filtra os menus baseado nos IDs contidos no array do documento do Perfil
    menusPermitidos = _todosMenus
        .where((menu) => _perfilAtual!.menusAcesso.contains(menu.id))
        .toList();

    submenusPermitidos = _todosSubmenus
        .where((submenu) => _perfilAtual!.submenusAcesso.contains(submenu.id))
        .toList();

    debugPrint("\n📊 [RELATÓRIO FINAL DE FILTRAGEM]");
    debugPrint(
      "   -> Menus que PASSARAM no filtro e VÃO APARECER na tela: ${menusPermitidos.length}",
    );
    if (menusPermitidos.isEmpty) {
      debugPrint(
        "      ⚠️ AVISO: Nenhum menu passou no filtro. Verifique se as strings do array 'menusAcesso' do Perfil batem com os IDs dos documentos da coleção 'menus'.",
      );
    } else {
      for (var menu in menusPermitidos) {
        debugPrint("      ✅ Exibindo Menu: '${menu.titulo}' (ID: ${menu.id})");
      }
    }
    debugPrint("=======================================================\n");
  }

  List<SubmenuItemModel> getSubmenusDoMenu(String menuId) {
    return submenusPermitidos.where((sub) => sub.menuId == menuId).toList();
  }
}
