import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vet_route/models/entregador_model.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/repositories/coleta_repository.dart';

class FirestoreColetaRepository implements ColetaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Clinica> obterClinicaLogada() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nenhum usuário autenticado no Firebase Auth!");
    }

    debugPrint(
      "🔍 DEBUG: O App está procurando na coleção 'clinicas' pelo documento com ID: ${user.uid}",
    );

    final doc = await _firestore.collection('clinicas').doc(user.uid).get();

    if (!doc.exists) {
      debugPrint("❌ DEBUG: Documento ${user.uid} NÃO EXISTE no Firestore!");
      throw Exception(
        "Perfil da clínica não encontrado para o UID: ${user.uid}",
      );
    }

    return Clinica.fromFirestore(doc);
  }

  @override
  Future<Laboratorio> obterLaboratorioPadrao() async {
    final snapshot = await _firestore.collection('laboratorios').limit(1).get();

    if (snapshot.docs.isEmpty) {
      throw Exception("Nenhum laboratório cadastrado no sistema.");
    }

    return Laboratorio.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<List<Entregador>> obterEntregadoresAtivos() async {
    final snapshot = await _firestore
        .collection('entregadores')
        .where('disponivel', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Entregador.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Coleta>> buscarColetasNoRadar() async {
    // Traz a lista completa sem filtrar status no banco, deixando a separação de abas para o Controller
    final snapColetas = await _firestore.collection('coletas').get();
    final snapInsumos = await _firestore.collection('pedidos_insumos').get();

    final coletas = snapColetas.docs.map((doc) => Coleta.fromFirestore(doc));
    final insumos = snapInsumos.docs.map((doc) => Coleta.fromFirestore(doc));

    return [...coletas, ...insumos];
  }

  @override
  Stream<List<Coleta>> streamColetasNoRadar() {
    // Removido o filtro 'whereIn' de status para permitir que finalizados, recusados e cancelados venham na stream
    final streamColetas = _firestore
        .collection('coletas')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    final streamInsumos = _firestore
        .collection('pedidos_insumos')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    return Rx.combineLatest2<List<Coleta>, List<Coleta>, List<Coleta>>(
      streamColetas,
      streamInsumos,
      (coletas, insumos) => [...coletas, ...insumos],
    );
  }

  @override
  Stream<List<Coleta>> streamColetasPorEntregador(String entregadorId) {
    // 1. Escuta a coleção 'coletas' verificando tanto 'entregadorId' quanto 'entregador.id'
    final streamColetasRaiz = _firestore
        .collection('coletas')
        .where('entregadorId', isEqualTo: entregadorId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    final streamColetasAninhado = _firestore
        .collection('coletas')
        .where('entregador.id', isEqualTo: entregadorId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    // 2. Escuta a coleção 'pedidos_insumos' verificando ambas as chaves de ID
    final streamInsumosRaiz = _firestore
        .collection('pedidos_insumos')
        .where('entregadorId', isEqualTo: entregadorId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    final streamInsumosAninhado = _firestore
        .collection('pedidos_insumos')
        .where('entregador.id', isEqualTo: entregadorId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    // 3. Combina os 4 fluxos unificando em uma única lista sem duplicidades
    return Rx.combineLatest4<
      List<Coleta>,
      List<Coleta>,
      List<Coleta>,
      List<Coleta>,
      List<Coleta>
    >(
      streamColetasRaiz,
      streamColetasAninhado,
      streamInsumosRaiz,
      streamInsumosAninhado,
      (c1, c2, i1, i2) {
        final mapaUnico = <String, Coleta>{};
        for (var item in [...c1, ...c2, ...i1, ...i2]) {
          mapaUnico[item.id] = item;
        }
        return mapaUnico.values.toList();
      },
    );
  }

  @override
  Future<void> solicitarColeta(Coleta novaColeta) async {
    await _firestore.collection('coletas').add(novaColeta.toMap());
  }

  @override
  Future<void> atualizarStatusColeta(String coletaId, String novoStatus) async {
    try {
      final docColeta = await _firestore
          .collection('coletas')
          .doc(coletaId)
          .get();

      if (docColeta.exists) {
        await _firestore.collection('coletas').doc(coletaId).update({
          'status': novoStatus,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('pedidos_insumos').doc(coletaId).update({
          'status': novoStatus,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status do pedido/coleta ($coletaId): $e");
      rethrow;
    }
  }
}
