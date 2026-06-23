import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/administrador_model.dart';
import '../models/perfil_usuario.dart';

class AdministradorAdminController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<Administrador>> administradores = ValueNotifier([]);

  // 💡 Lista APENAS quem tem o perfil de administrador
  void ouvirAdministradores() {
    _db
        .collection('usuarios')
        .where('perfil', isEqualTo: PerfilUsuario.administrador.firebaseValue)
        .snapshots()
        .listen((snapshot) {
          administradores.value = snapshot.docs
              .map((doc) => Administrador.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> salvarAdministrador(Administrador admin) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').add(admin.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar administrador: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> atualizarAdministrador(String id, Administrador admin) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).update(admin.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar administrador: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletarAdministrador(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar administrador: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    administradores.dispose();
  }
}
