import 'package:google_maps_flutter/google_maps_flutter.dart';

class Endereco {
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado; // UF
  final double? latitude;
  final double? longitude;

  Endereco({
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.latitude,
    this.longitude,
  });

  LatLng? get coordenada {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

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
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }
}
