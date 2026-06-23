import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinica_model.dart';
import '../models/perfil_usuario.dart';

class ClinicaAdminController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<Clinica>> clinicas = ValueNotifier([]);

  void ouvirClinicas() {
    _db
        .collection('usuarios')
        .where('perfil', isEqualTo: PerfilUsuario.clinica.firebaseValue)
        .snapshots()
        .listen((snapshot) {
          clinicas.value = snapshot.docs
              .map((doc) => Clinica.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> salvarClinica(Clinica clinica) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').add(clinica.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar clínica: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> atualizarClinica(String id, Clinica clinica) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).update(clinica.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar clínica: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletarClinica(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar clínica: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    clinicas.dispose();
  }
}
