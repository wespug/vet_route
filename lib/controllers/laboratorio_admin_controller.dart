import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import '../models/laboratorio_model.dart';

class LaboratorioAdminController with LoggerMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _colLab = 'laboratorios';

  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  final ValueNotifier<List<Laboratorio>> laboratorios = ValueNotifier([]);

  Future<bool> salvarLaboratorio(Laboratorio laboratorio) async {
    isLoading.value = true;
    try {
      log.i('Salvando laboratório na coleção: $_colLab');
      await _db.collection(_colLab).add(laboratorio.toMap());
      log.i('Laboratório salvo com sucesso!');
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar laboratório: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  StreamSubscription? _streamSubscription;

  void ouvirLaboratorios() {
    // Se já havia alguém ouvindo, mandamos parar primeiro para não duplicar
    _streamSubscription?.cancel();

    _streamSubscription = _db.collection(_colLab).snapshots().listen((
      snapshot,
    ) {
      laboratorios.value = snapshot.docs
          .map((doc) => Laboratorio.fromFirestore(doc))
          .toList();
    });
  }

  Future<bool> atualizarLaboratorio(String id, Laboratorio laboratorio) async {
    isLoading.value = true;
    try {
      await _db.collection(_colLab).doc(id).update(laboratorio.toMap());
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
      await _db.collection(_colLab).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar laboratório: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _streamSubscription?.cancel();
    isLoading.dispose();
    laboratorios.dispose();
  }
}
