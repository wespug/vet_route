import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/laboratorio_model.dart';
import '../models/perfil_usuario.dart'; // 💡 Importação vital para usar o Enum

class LaboratorioAdminController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<Laboratorio>> laboratorios = ValueNotifier([]);

  void ouvirLaboratorios() {
    _db
        .collection('usuarios')
        // 💡 Blindado: usando o Enum no lugar da string solta 'laboratorio'
        .where('perfil', isEqualTo: PerfilUsuario.laboratorio.firebaseValue)
        .snapshots()
        .listen((snapshot) {
          laboratorios.value = snapshot.docs
              .map((doc) => Laboratorio.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> salvarLaboratorio(Laboratorio laboratorio) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').add(laboratorio.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar laboratório: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> atualizarLaboratorio(String id, Laboratorio laboratorio) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).update(laboratorio.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar laboratório: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletarLaboratorio(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar laboratório: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    laboratorios.dispose();
  }
}
