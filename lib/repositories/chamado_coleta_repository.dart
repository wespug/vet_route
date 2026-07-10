import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chamado_coleta_model.dart';

class ChamadoColetaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> criarChamado(ChamadoColetaModel chamado) async {
    await _firestore.collection('chamados_coleta').add(chamado.toMap());
  }

  // Stream reativa para chamados ativos (Aguardando ou Em Trânsito)
  Stream<List<ChamadoColetaModel>> obterChamadosAtivos(String clinicaId) {
    return _firestore
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: clinicaId)
        .where('status', whereIn: ['aguardando', 'em_transito'])
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ChamadoColetaModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Consulta paginada via cursor para o histórico de concluídos
  Future<QuerySnapshot> obterHistoricoPaginado(
    String clinicaId, {
    DocumentSnapshot? ultimoDocumento,
    int limite = 5,
  }) async {
    Query query = _firestore
        .collection('chamados_coleta')
        .where('clinicaId', isEqualTo: clinicaId)
        .where('status', isEqualTo: 'concluido')
        .orderBy('dataCriacao', descending: true)
        .limit(limite);

    if (ultimoDocumento != null) {
      query = query.startAfterDocument(ultimoDocumento);
    }

    return await query.get();
  }
}
