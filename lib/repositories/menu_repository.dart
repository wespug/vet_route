import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/menu_item_model.dart';

class MenuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MenuItemModel>> buscarMenus() async {
    try {
      final snapshot = await _firestore
          .collection('menus')
          .orderBy('titulo')
          .get();
      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar menus no Firestore: $e");
    }
  }

  Future<String> salvarMenu(MenuItemModel menu) async {
    try {
      final docRef = await _firestore.collection('menus').add(menu.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Erro ao salvar menu no Firestore: $e");
    }
  }

  // 💡 NOVO: Método para persistir as alterações de um menu no Firestore
  Future<void> atualizarMenu(String menuId, MenuItemModel menu) async {
    try {
      await _firestore.collection('menus').doc(menuId).update(menu.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar menu no Firestore: $e");
    }
  }

  Future<void> deletarMenu(String menuId) async {
    try {
      await _firestore.collection('menus').doc(menuId).delete();
    } catch (e) {
      throw Exception("Erro ao deletar menu no Firestore: $e");
    }
  }
}
