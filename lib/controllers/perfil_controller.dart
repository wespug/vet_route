import 'package:flutter/material.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';
import 'package:vet_route/repositories/perfil_repository.dart';

class PerfilController extends ChangeNotifier {
  final PerfilRepository _repository = PerfilRepository();

  List<PerfilAcesso> _perfis = [];
  List<PerfilAcesso> get perfis => _perfis;

  bool _carregando = false;
  bool get carregando => _carregando;

  Future<void> carregarPerfis() async {
    _carregando = true;
    notifyListeners();
    try {
      _perfis = await _repository.buscarPerfis();
    } catch (e) {
      debugPrint("Erro na controller de perfis globais: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // 💡 AGORA COM 6 ARGUMENTOS: Recebe a lista exibirEm
  Future<void> adicionarPerfil(
    String nome,
    List<String> menus,
    List<String> submenus,
    bool visivelWeb,
    bool visivelApp,
    List<String> exibirEm, // 💡 Injetado aqui para casar com a View!
  ) async {
    if (nome.isEmpty) return;

    final novoPerfil = PerfilAcesso(
      id: '',
      nome: nome,
      menusAcesso: menus,
      submenusAcesso: submenus,
      visivelWeb: visivelWeb,
      visivelApp: visivelApp,
      exibirEm: exibirEm, // 💡 Repassando ao modelo
    );
    await _repository.salvarPerfil(novoPerfil);
    await carregarPerfis();
  }

  // 💡 AGORA COM 7 ARGUMENTOS: Recebe a lista exibirEm
  Future<void> editarPerfil(
    String id,
    String nome,
    List<String> menus,
    List<String> submenus,
    bool visivelWeb,
    bool visivelApp,
    List<String> exibirEm, // 💡 Injetado aqui para casar com a View!
  ) async {
    if (nome.isEmpty) return;

    final perfilAtualizado = PerfilAcesso(
      id: id,
      nome: nome,
      menusAcesso: menus,
      submenusAcesso: submenus,
      visivelWeb: visivelWeb,
      visivelApp: visivelApp,
      exibirEm: exibirEm, // 💡 Atualizando no modelo
    );
    await _repository.atualizarPerfil(id, perfilAtualizado);
    await carregarPerfis();
  }

  Future<void> excluirPerfil(String perfilId) async {
    await _repository.deletarPerfil(perfilId);
    await carregarPerfis();
  }
}
