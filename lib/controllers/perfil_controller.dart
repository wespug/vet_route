import 'package:flutter/material.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';
import 'package:vet_route/repositories/perfil_repository.dart';

class PerfilController extends ChangeNotifier {
  final PerfilRepository _repository = PerfilRepository();

  List<PerfilAcesso> _perfis = [];
  List<PerfilAcesso> get perfis => _perfis;

  bool _carregando = false;
  bool get carregando => _carregando;

  // 💡 MUDANÇA: Métodos agora não exigem mais IDs externos
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

  Future<void> adicionarPerfil(String nome) async {
    if (nome.isEmpty) return;

    final novoPerfil = PerfilAcesso(id: '', nome: nome);
    await _repository.salvarPerfil(novoPerfil);
    await carregarPerfis(); // Atualiza a lista global
  }

  Future<void> excluirPerfil(String perfilId) async {
    await _repository.deletarPerfil(perfilId);
    await carregarPerfis();
  }
}
