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
    final snapColetas = await _firestore.collection('coletas').get();
    final snapInsumos = await _firestore.collection('pedidos_insumos').get();
    final snapChamados = await _firestore
        .collection('chamados_coleta')
        .get(); // 💡 ADICIONADO

    final coletas = snapColetas.docs.map((doc) => Coleta.fromFirestore(doc));
    final insumos = snapInsumos.docs.map((doc) => Coleta.fromFirestore(doc));
    final chamados = snapChamados.docs.map((doc) => Coleta.fromFirestore(doc));

    final mapaUnico = <String, Coleta>{};
    for (var item in [...coletas, ...insumos, ...chamados]) {
      mapaUnico[item.id] = item; // Remove duplicatas priorizando o último lido
    }

    return mapaUnico.values.toList();
  }

  @override
  Stream<List<Coleta>> streamColetasNoRadar() {
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

    // 💡 A PEÇA QUE FALTAVA NO RADAR GLOBAL
    final streamChamados = _firestore
        .collection('chamados_coleta')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    return Rx.combineLatest3<
      List<Coleta>,
      List<Coleta>,
      List<Coleta>,
      List<Coleta>
    >(streamColetas, streamInsumos, streamChamados, (
      coletas,
      insumos,
      chamados,
    ) {
      final mapaUnico = <String, Coleta>{};
      for (var item in [...coletas, ...insumos, ...chamados]) {
        mapaUnico[item.id] = item;
      }
      return mapaUnico.values.toList();
    });
  }

  @override
  Stream<List<Coleta>> streamColetasPorEntregador(String entregadorId) {
    // 1. Escuta a coleção 'coletas'
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

    // 2. Escuta a coleção 'pedidos_insumos'
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

    // 3. 💡 A PEÇA DE OURO: Escutando a tabela onde o laboratório injeta a corrida do motoboy!
    final streamChamadosColeta = _firestore
        .collection('chamados_coleta')
        .where('entregadorId', isEqualTo: entregadorId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Coleta.fromFirestore(doc)).toList(),
        );

    // Combina os 5 fluxos unificando em uma única lista
    return Rx.combineLatest5<
      List<Coleta>,
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
      streamChamadosColeta, // Entra por último para os dados enriquecidos sobrescreverem se houver ID igual!
      (c1, c2, i1, i2, chamados) {
        final mapaUnico = <String, Coleta>{};
        for (var item in [...c1, ...c2, ...i1, ...i2, ...chamados]) {
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
      // 1. Monta o pacote base de atualização
      final Map<String, dynamic> dadosAtualizacao = {'status': novoStatus};

      // 2. Se o status virou "aguardando", o motoboy recusou. Apaga o ID e o Nome dele.
      if (novoStatus == 'aguardando_entregador' ||
          novoStatus == 'aguardando_coleta') {
        dadosAtualizacao['entregadorId'] = FieldValue.delete();
        dadosAtualizacao['nomeEntregador'] = FieldValue.delete();
        dadosAtualizacao['entregador'] = FieldValue.delete();
      }

      // 3. Varre as tabelas disparando a atualização
      final docColeta = await _firestore
          .collection('coletas')
          .doc(coletaId)
          .get();
      if (docColeta.exists) {
        dadosAtualizacao['dataAtualizacao'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('coletas')
            .doc(coletaId)
            .update(dadosAtualizacao);
      }

      final docInsumo = await _firestore
          .collection('pedidos_insumos')
          .doc(coletaId)
          .get();
      if (docInsumo.exists) {
        dadosAtualizacao['dataAtualizacao'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('pedidos_insumos')
            .doc(coletaId)
            .update(dadosAtualizacao);
      }

      final docChamado = await _firestore
          .collection('chamados_coleta')
          .doc(coletaId)
          .get();
      if (docChamado.exists) {
        dadosAtualizacao['atualizadoEm'] = FieldValue.serverTimestamp();
        dadosAtualizacao.remove('dataAtualizacao');
        await _firestore
            .collection('chamados_coleta')
            .doc(coletaId)
            .update(dadosAtualizacao);
      }
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status do pedido/coleta ($coletaId): $e");
      rethrow;
    }
  }
}
