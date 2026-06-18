// lib/models/clinica_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'endereco_model.dart';

class Clinica {
  final String id;
  final String nome;
  final String telefone;
  final Endereco endereco;

  Clinica({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
  });

  // O Pulo do Gato: Converte o DocumentSnapshot do Firestore para o Objeto do App
  factory Clinica.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final enderecoMap = data['endereco'] as Map<String, dynamic>;

    return Clinica(
      id: doc.id, // O ID do documento é o UID do usuário
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
