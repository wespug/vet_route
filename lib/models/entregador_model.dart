// lib/models/entregador_model.dart

import 'veiculo_model.dart'; // Importamos o modelo do veículo

class Entregador {
  final String id;
  final String nome;
  final String telefone;
  final Veiculo veiculo; // O entregador agora "possui" um objeto Veiculo

  Entregador({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.veiculo,
  });
}
