import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';

class PerfilRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PerfilAcesso>> buscarPerfis() async {
    try {
      final snapshot = await _firestore
          .collection('perfis')
          .orderBy('nome')
          .get();
      return snapshot.docs
          .map((doc) => PerfilAcesso.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar perfis no Firestore: $e");
    }
  }

  Future<String> salvarPerfil(PerfilAcesso perfil) async {
    try {
      final docRef = await _firestore.collection('perfis').add(perfil.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Erro ao salvar perfil no Firestore: $e");
    }
  }

  // 💡 NOVO: Atualizar as permissões de um perfil existente
  Future<void> atualizarPerfil(String perfilId, PerfilAcesso perfil) async {
    try {
      await _firestore
          .collection('perfis')
          .doc(perfilId)
          .update(perfil.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar perfil no Firestore: $e");
    }
  }

  Future<void> deletarPerfil(String perfilId) async {
    try {
      await _firestore.collection('perfis').doc(perfilId).delete();
    } catch (e) {
      throw Exception("Erro ao deletar perfil no Firestore: $e");
    }
  }
}
