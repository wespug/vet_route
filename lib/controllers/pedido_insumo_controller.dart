import 'package:flutter/material.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';
import 'package:vet_route/repositories/pedido_insumo_repository.dart';

class PedidoInsumoController extends ChangeNotifier {
  final PedidoInsumoRepository _repository = PedidoInsumoRepository();

  List<PedidoInsumoModel> pedidos = [];
  bool carregando = true;

  void escutarPedidos(String laboratorioId) {
    _repository
        .streamPedidosPorLaboratorio(laboratorioId)
        .listen(
          (lista) {
            pedidos = lista;
            carregando = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Erro ao escutar pedidos: $e");
            carregando = false;
            notifyListeners();
          },
        );
  }

  Future<void> alterarStatus(String pedidoId, String novoStatus) async {
    try {
      await _repository.atualizarStatusPedido(pedidoId, novoStatus);
      // Não precisamos chamar notifyListeners() porque a Stream atualizará a tela automaticamente
    } catch (e) {
      debugPrint("Erro ao atualizar status: $e");
      rethrow;
    }
  }
}
