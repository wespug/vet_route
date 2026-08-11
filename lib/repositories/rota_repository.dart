import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/rota_model.dart';

class RotaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- SEUS MÉTODOS JÁ EXISTENTES ---

  Future<void> adicionarRota(RotaModel rota) async {
    await _firestore.collection('rotas_fixas').add(rota.toMap());
  }

  Future<void> atualizarRota(String rotaId, RotaModel rota) async {
    await _firestore.collection('rotas_fixas').doc(rotaId).update(rota.toMap());
  }

  Future<List<RotaModel>> buscarRotasPorLaboratorio(
    String laboratorioId,
  ) async {
    final snapshot = await _firestore
        .collection('rotas_fixas')
        .where('laboratorioId', isEqualTo: laboratorioId)
        .get();

    return snapshot.docs.map((doc) => RotaModel.fromFirestore(doc)).toList();
  }

  Future<void> deletarRota(String rotaId) async {
    await _firestore.collection('rotas_fixas').doc(rotaId).delete();
  }

  // --- MÉTODO NECESSÁRIO PARA O CONTROLLER ---

  /// Busca as rotas ativas na coleção 'rotas_fixas'
  Future<List<RotaModel>> buscarRotasAtivas(String laboratorioId) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (laboratorioId.isNotEmpty) {
      snapshot = await _firestore
          .collection('rotas_fixas')
          .where('laboratorioId', isEqualTo: laboratorioId)
          .where('ativa', isEqualTo: true)
          .get();
    } else {
      snapshot = await _firestore
          .collection('rotas_fixas')
          .where('ativa', isEqualTo: true)
          .get();
    }

    return snapshot.docs.map((doc) => RotaModel.fromFirestore(doc)).toList();
  }
}
