import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/insumo_model.dart';

class InsumoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> adicionarInsumo(InsumoModel insumo) async {
    await _firestore.collection('insumos').add(insumo.toMap());
  }

  Future<List<InsumoModel>> buscarInsumosPorLaboratorio(
    String laboratorioId,
  ) async {
    final snapshot = await _firestore
        .collection('insumos')
        .where('laboratorioId', isEqualTo: laboratorioId)
        .get();

    return snapshot.docs.map((doc) => InsumoModel.fromFirestore(doc)).toList();
  }

  Future<void> deletarInsumo(String insumoId) async {
    await _firestore.collection('insumos').doc(insumoId).delete();
  }
}
