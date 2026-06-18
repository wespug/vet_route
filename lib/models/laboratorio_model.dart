// lib/models/laboratorio_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'endereco_model.dart';

class Laboratorio {
  final String id;
  final String nome;
  final String telefone;
  final Endereco endereco;

  Laboratorio({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
  });

  /// Mapeia o DocumentSnapshot do Firestore diretamente para o objeto Laboratorio
  factory Laboratorio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extrai o mapa interno de endereço
    final enderecoMap = data['endereco'] as Map<String, dynamic>;

    return Laboratorio(
      id: doc.id, // O ID do documento é o UID do utilizador autenticado
      nome: data['nome'] ?? '',
      telefone: data['telefone'] ?? '',
      endereco: Endereco(
        nome: enderecoMap['nome'] ?? '',
        rua: enderecoMap['rua'] ?? '',
        cep: enderecoMap['cep'] ?? '',
        cidade: enderecoMap['cidade'] ?? '',
        estado: enderecoMap['estado'] ?? '',
        pais: enderecoMap['pais'] ?? '',
        coordenada: LatLng(
          (enderecoMap['latitude'] as num).toDouble(),
          (enderecoMap['longitude'] as num).toDouble(),
        ),
      ),
    );
  }
}
