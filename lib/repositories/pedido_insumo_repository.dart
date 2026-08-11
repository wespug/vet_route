import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';

class PedidoInsumoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca todos os pedidos direcionados a um laboratório específico em tempo real
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

  /// Atualiza o status simples do pedido
  Future<void> atualizarStatusPedido(String pedidoId, String novoStatus) async {
    await _firestore.collection('pedidos_insumos').doc(pedidoId).update({
      'status': novoStatus,
      'dataAtualizacao': FieldValue.serverTimestamp(),
    });
  }

  /// Atualiza o status de forma detalhada, gravando o histórico e vinculando o entregador (quando houver)
  Future<void> atualizarStatusDetalhado({
    required String pedidoId,
    required String novoStatus,
    required Map<String, dynamic> itemHistorico,
    String? entregadorId,
    String? nomeEntregador,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': novoStatus,
      'dataAtualizacao': FieldValue.serverTimestamp(),
      'historico': FieldValue.arrayUnion([itemHistorico]),
    };

    if (entregadorId != null) updateData['entregadorId'] = entregadorId;
    if (nomeEntregador != null) updateData['nomeEntregador'] = nomeEntregador;

    await _firestore
        .collection('pedidos_insumos')
        .doc(pedidoId)
        .update(updateData);
  }
}
