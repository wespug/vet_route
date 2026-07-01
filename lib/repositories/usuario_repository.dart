import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/usuario_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UsuarioModel>> buscarUsuarios() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .orderBy('nome')
          .get();
      return snapshot.docs
          .map((doc) => UsuarioModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar usuários: $e");
    }
  }

  Future<String> salvarUsuario(UsuarioModel usuario, String senha) async {
    try {
      // 1. Cria o e-mail e senha de verdade no Firebase Authentication
      UserCredential credenciais = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: usuario.email,
            password: senha,
          );

      // 2. Salva o perfil no Firestore usando o UID que o Auth gerou!
      await _firestore
          .collection('usuarios')
          .doc(credenciais.user!.uid)
          .set(usuario.toMap());

      return credenciais.user!.uid;
    } catch (e) {
      throw Exception("Erro ao salvar usuário: $e");
    }
  }

  Future<void> atualizarUsuario(
    String usuarioId,
    UsuarioModel usuario,
    String novaSenha,
  ) async {
    try {
      // Atualiza os dados no banco
      await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .update(usuario.toMap());

      // (Opcional no futuro: Adicionar lógica para forçar a troca de senha do usuário no Auth se novaSenha não for vazia)
    } catch (e) {
      throw Exception("Erro ao atualizar usuário: $e");
    }
  }

  Future<void> deletarUsuario(String usuarioId) async {
    try {
      await _firestore.collection('usuarios').doc(usuarioId).delete();
    } catch (e) {
      throw Exception("Erro ao deletar usuário: $e");
    }
  }
}
