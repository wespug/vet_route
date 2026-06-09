// lib/models/endereco_model.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

class Endereco {
  final String nome; // Ex: Clínica Vida Animal ou João da Silva
  final String rua; // Ex: Rua dos Cachorros, 123
  final String cep; // Ex: 05717170-0
  final String cidade; // Ex: São Paulo
  final String estado; // Ex: São Paulo
  final String pais; // Ex: São Paulo

  // O '?' significa que este campo é opcional (pode ser null)
  final String? pontoReferencia;
  final String? telefoneContato;
  final LatLng? coordenada; // A posição no mapa

  Endereco({
    required this.nome,
    required this.rua,
    required this.cep,
    required this.cidade,
    required this.estado,
    required this.pais,
    this.pontoReferencia,
    this.telefoneContato,
    this.coordenada,
  });
}
