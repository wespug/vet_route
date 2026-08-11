import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoInsumoService {
  final FirebaseFirestore _firestore;

  PedidoInsumoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Atualiza o status e adiciona um item ao histórico do pedido
  Future<void> atualizarStatusPedido({
    required String pedidoId,
    required String novoStatus,
    required String observacao,
    String usuario = 'Operador do Laboratório',
    String? entregadorId,
    String? nomeEntregador,
  }) async {
    final dataAtual = DateTime.now().toIso8601String();

    final Map<String, dynamic> itemHistorico = {
      'status': novoStatus,
      'data': dataAtual,
      'observacao': observacao,
      'usuario': usuario,
    };

    if (entregadorId != null) itemHistorico['entregadorId'] = entregadorId;
    if (nomeEntregador != null)
      itemHistorico['nomeEntregador'] = nomeEntregador;

    final Map<String, dynamic> updateData = {
      'status': novoStatus,
      'historico': FieldValue.arrayUnion([itemHistorico]),
    };

    if (entregadorId != null) updateData['entregadorId'] = entregadorId;
    if (nomeEntregador != null) updateData['nomeEntregador'] = nomeEntregador;

    await _firestore
        .collection('pedidos_insumos')
        .doc(pedidoId)
        .update(updateData);
  }

  /// Busca as rotas cadastradas para determinado laboratório
  Future<List<Map<String, dynamic>>> buscarRotasLaboratorio(
    String laboratorioId,
  ) async {
    final snapshot = await _firestore
        .collection('rotas')
        .where('laboratorioId', isEqualTo: laboratorioId)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
