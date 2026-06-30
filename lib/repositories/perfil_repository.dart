import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/perfil_acesso_model.dart';

class PerfilRepository {
  // 💡 Instância real do Firestore conectada!
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1) LER: Busca todos os perfis na raiz do banco (Atende seu requisito 2)
  Future<List<PerfilAcesso>> buscarPerfis() async {
    try {
      // Busca a coleção 'perfis' e já ordena pelo nome em ordem alfabética
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

  // 2) CRIAR: Salva direto no banco (Atende seu requisito 1)
  Future<String> salvarPerfil(PerfilAcesso perfil) async {
    try {
      final docRef = await _firestore.collection('perfis').add(perfil.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Erro ao salvar perfil no Firestore: $e");
    }
  }

  // 3) DELETAR: Remove o documento pela ID (Atende seu requisito 3)
  Future<void> deletarPerfil(String perfilId) async {
    try {
      await _firestore.collection('perfis').doc(perfilId).delete();
    } catch (e) {
      throw Exception("Erro ao deletar perfil no Firestore: $e");
    }
  }
}
