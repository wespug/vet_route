import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exame_model.dart';

class ExameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> adicionarExame(ExameModel exame) async {
    await _firestore.collection('exames').add(exame.toMap());
  }

  Future<List<ExameModel>> buscarExamesPorLaboratorio(
    String laboratorioId,
  ) async {
    final snapshot = await _firestore
        .collection('exames')
        .where('laboratorioId', isEqualTo: laboratorioId)
        .get();

    return snapshot.docs.map((doc) => ExameModel.fromFirestore(doc)).toList();
  }

  Future<void> deletarExame(String exameId) async {
    await _firestore.collection('exames').doc(exameId).delete();
  }
}
