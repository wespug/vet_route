import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entregador_model.dart';

class EntregadorAdminController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<Entregador>> entregadores = ValueNotifier([]);

  void ouvirEntregadores() {
    _db
        .collection('usuarios')
        .where('perfil', isEqualTo: 'entregadores') // Conforme seu enum/main
        .snapshots()
        .listen((snapshot) {
          entregadores.value = snapshot.docs
              .map((doc) => Entregador.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> salvarEntregador(Entregador entregador) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').add(entregador.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar entregador: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> atualizarEntregador(String id, Entregador entregador) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).update(entregador.toMap());
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar entregador: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletarEntregador(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar entregador: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
