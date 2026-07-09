import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rota_model.dart';

class RotaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
