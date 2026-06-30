import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/submenu_item_model.dart';

class SubmenuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SubmenuItemModel>> buscarSubmenus() async {
    try {
      final snapshot = await _firestore
          .collection('submenus')
          .orderBy('titulo')
          .get();
      return snapshot.docs
          .map((doc) => SubmenuItemModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar submenus no Firestore: $e");
    }
  }

  Future<String> salvarSubmenu(SubmenuItemModel submenu) async {
    try {
      final docRef = await _firestore
          .collection('submenus')
          .add(submenu.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Erro ao salvar submenu no Firestore: $e");
    }
  }

  Future<void> deletarSubmenu(String submenuId) async {
    try {
      await _firestore.collection('submenus').doc(submenuId).delete();
    } catch (e) {
      throw Exception("Erro ao deletar submenu no Firestore: $e");
    }
  }
}
