// lib/models/veiculo_model.dart

// Criamos uma lista fechada de opções válidas para o sistema
enum TipoVeiculo { moto, carro, uber, taxi, aviao }

class Veiculo {
  final TipoVeiculo tipo;
  final String? placa; // Opcional, pois bicicleta não tem placa
  final String? modelo; // Ex: Honda CG 160, Boeing 737...
  final String? cor;

  Veiculo({required this.tipo, this.placa, this.modelo, this.cor});
}
