import 'package:flutter/material.dart';
import 'package:vet_route/models/usuario_model.dart';
import 'package:vet_route/repositories/usuario_repository.dart';

class UsuarioController extends ChangeNotifier {
  final UsuarioRepository _repository = UsuarioRepository();

  List<UsuarioModel> _usuarios = [];
  List<UsuarioModel> get usuarios => _usuarios;

  bool _carregando = false;
  bool get carregando => _carregando;

  Future<void> carregarUsuarios() async {
    _carregando = true;
    notifyListeners();
    try {
      _usuarios = await _repository.buscarUsuarios();
    } catch (e) {
      debugPrint("Erro na controller de usuários: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvarUsuario(
    String id,
    String nome,
    String email,
    String senha, // <-- Adicionamos a Senha aqui
    String perfilId,
    String vinculoId,
    bool ativo,
  ) async {
    if (nome.isEmpty || email.isEmpty || perfilId.isEmpty) return;

    _carregando = true;
    notifyListeners();

    try {
      final novoUsuario = UsuarioModel(
        id: id,
        nome: nome,
        email: email,
        perfilId: perfilId,
        vinculoId: vinculoId,
        ativo: ativo,
      );

      if (id.isEmpty) {
        // Envia a senha para criar o usuário no Auth
        await _repository.salvarUsuario(novoUsuario, senha);
      } else {
        // Envia a senha para caso o usuário queira atualizar a senha
        await _repository.atualizarUsuario(id, novoUsuario, senha);
      }

      await carregarUsuarios();
    } catch (e) {
      debugPrint("Erro ao salvar usuário: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> excluirUsuario(String usuarioId) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repository.deletarUsuario(usuarioId);
      await carregarUsuarios();
    } catch (e) {
      debugPrint("Erro ao excluir usuário: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
