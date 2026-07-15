import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';

class PedidoInsumoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Busca todos os pedidos direcionados a um laboratório específico
  Stream<List<PedidoInsumoModel>> streamPedidosPorLaboratorio(
    String laboratorioId,
  ) {
    return _firestore
        .collection('pedidos_insumos')
        .where('laboratorioId', isEqualTo: laboratorioId)
        .orderBy('dataSolicitacao', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PedidoInsumoModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Atualiza o status do pedido
  Future<void> atualizarStatusPedido(String pedidoId, String novoStatus) async {
    await _firestore.collection('pedidos_insumos').doc(pedidoId).update({
      'status': novoStatus,
      'dataAtualizacao': FieldValue.serverTimestamp(),
    });
  }
}
