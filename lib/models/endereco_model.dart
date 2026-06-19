class Endereco {
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado; // UF
  final double? latitude; // 💡 Pensando no futuro do mapa!
  final double? longitude;

  Endereco({
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento = '',
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.latitude,
    this.longitude,
  });

  // Transforma o objeto Dart em um Map para o Firebase
  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Constrói o objeto Dart a partir do Map do Firebase
  factory Endereco.fromMap(Map<String, dynamic> map) {
    return Endereco(
      cep: map['cep'] ?? '',
      logradouro: map['logradouro'] ?? '',
      numero: map['numero'] ?? '',
      complemento: map['complemento'] ?? '',
      bairro: map['bairro'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      // Tratamento seguro para double no Firestore
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }
}
