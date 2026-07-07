class Veiculo {
  final String placa;
  final String modelo;
  final String cor;
  final String tipo; // Ex: Moto, Carro, Van

  Veiculo({
    required this.placa,
    required this.modelo,
    required this.cor,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {'placa': placa, 'modelo': modelo, 'cor': cor, 'tipo': tipo};
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      placa: map['placa'] ?? '',
      modelo: map['modelo'] ?? '',
      cor: map['cor'] ?? '',
      tipo: map['tipo'] ?? 'Moto',
    );
  }
}
